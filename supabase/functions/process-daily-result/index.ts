// ====================================================================================
// EDGE FUNCTION: process-daily-result
// DESCRIPTION: This is the core accountability engine for ScreenPledge. It is the
//              single, authoritative source of truth for processing a user's daily
//              outcome. It is designed to be secure, idempotent, and robust.
//
// INVOCATION:  Called by the client app's background task to submit the final
//              data for a completed day.
//
// PAYLOAD:     {
//                "date": "YYYY-MM-DD",
//                "timezone": "IANA/Timezone",
//                "final_usage_seconds": integer
//              }
// ====================================================================================

// Import necessary libraries.
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient, SupabaseClientOptions } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@11.1.0';
import { Resend } from 'https://esm.sh/resend@3.4.0';
import { corsHeaders } from '../_shared/cors.ts';

// Initialize the Stripe SDK with the secret key stored securely in Supabase secrets.
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

// Initialize the Resend SDK for sending transactional emails.
const resend = new Resend(Deno.env.get('RESEND_API_KEY')!);

// The main function that handles incoming requests.
serve(async (req) => {
  // Handle the CORS preflight request. This is a standard security requirement.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // --- 1. INITIALIZATION & AUTHENTICATION ---

    // Configure the Supabase admin client. These options are crucial for server-side
    // operations, forcing it to use the service_role key and ignore user sessions.
    const adminAuthClientOptions: SupabaseClientOptions<"public"> = {
      auth: { autoRefreshToken: false, persistSession: false }
    };

    // Create the Supabase admin client, which has superuser privileges to bypass RLS.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      adminAuthClientOptions
    );

    // Create a standard client to safely get the user's identity from the request header.
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    // Get the authenticated user. If no valid JWT is provided, throw an error.
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      throw new Error('Authentication error: User not found');
    }

    // --- 2. DATA VALIDATION & PRE-PROCESSING ---

    // Parse the incoming request body from the client app.
    const { date, timezone, final_usage_seconds } = await req.json();

    // Validate that all required data is present.
    if (!date || !timezone || final_usage_seconds === undefined) {
      throw new Error('Invalid request: Missing required fields (date, timezone, final_usage_seconds).');
    }

    // --- 3. THE IMMUTABILITY CHECK (PREVENT OVERWRITES) ---

    // Query the database to see if a result for this user and date already exists.
    // This is the core of our "ungameable" system. The past is immutable.
    const { data: existingResult, error: checkError } = await supabaseAdmin
      .from('daily_results')
      .select('id')
      .eq('user_id', user.id)
      .eq('date', date)
      .single();

    if (checkError && checkError.code !== 'PGRST116') { // PGRST116 means "No rows found", which is okay.
      throw checkError;
    }

    // If a record already exists, we do not process this request.
    // This prevents a user from ever overwriting a past failure.
    if (existingResult) {
      return new Response(JSON.stringify({ message: 'Result for this date has already been processed.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // --- 4. FETCH AUTHORITATIVE DATA (PROFILE & GOAL) ---

    // Fetch the user's profile to get their pledge status and Stripe ID.
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('pledge_status, pledge_amount_cents, stripe_customer_id, email')
      .eq('id', user.id)
      .single();

    if (profileError) throw profileError;

    // Fetch the user's active goal for the specific date provided by the client.
    // This query correctly finds the goal that was effective at the start of that day.
    const { data: goal, error: goalError } = await supabaseAdmin
      .from('goals')
      .select('time_limit_seconds')
      .eq('user_id', user.id)
      .lte('effective_at', `${date}T23:59:59Z`) // Goal must have started on or before this date.
      .or(`ended_at.is.null,ended_at.gt.${date}T00:00:00Z`) // Goal must not have ended before this date.
      .order('effective_at', { ascending: false }) // Get the most recent one if multiple match.
      .limit(1)
      .single();

    if (goalError && goalError.code !== 'PGRST116') {
      throw goalError;
    }

    // If the user had no active goal for that day, we record a success with 0 points.
    if (!goal) {
      await supabaseAdmin.from('daily_results').insert({
        user_id: user.id,
        date: date,
        outcome: 'success',
        pp_earned: 0,
        time_spent_seconds: final_usage_seconds,
        timezone: timezone, // Lock in the timezone for the day.
      });
      return new Response(JSON.stringify({ message: 'Success (no active goal).'}), { status: 200 });
    }

    // --- 5. DETERMINE OUTCOME & EXECUTE LOGIC ---

    const timeLimit = goal.time_limit_seconds;
    const hasActivePledge = profile.pledge_status === 'active' && profile.pledge_amount_cents > 0;

    // Compare the user's final usage to their goal limit.
    if (final_usage_seconds <= timeLimit) {
      // --- SUCCESS OUTCOME ---
      const pointsEarned = hasActivePledge ? 10 : 1; // 10x points for users with a pledge.

      // Atomically update the user's profile (add points, increment streak).
      await supabaseAdmin.rpc('update_profile_on_success', {
        user_id_input: user.id,
        points_to_add: pointsEarned,
      });

      // Insert the final, authoritative success record.
      await supabaseAdmin.from('daily_results').insert({
        user_id: user.id,
        date: date,
        outcome: 'success',
        pp_earned: pointsEarned,
        time_spent_seconds: final_usage_seconds,
        time_limit_seconds: timeLimit,
        timezone: timezone,
      });

    } else {
      // --- FAILURE OUTCOME ---
      let chargedAmount = 0;

      // Only process a charge if the user has an active pledge and a Stripe customer ID.
      if (hasActivePledge && profile.stripe_customer_id) {
        try {
          // Initiate the charge with Stripe.
          await stripe.charges.create({
            amount: profile.pledge_amount_cents,
            currency: 'usd',
            customer: profile.stripe_customer_id,
            description: `ScreenPledge Accountability Charge for ${date}`,
          });
          chargedAmount = profile.pledge_amount_cents;

          // On successful charge, send an email receipt via Resend.
          await resend.emails.send({
            from: 'receipts@screenpledge.app', // Replace with your domain
            to: profile.email,
            subject: `ScreenPledge Receipt for ${date}`,
            html: `<h1>Pledge Processed</h1><p>Hi there, this is a confirmation that your pledge of $${(chargedAmount / 100).toFixed(2)} has been processed for exceeding your screen time limit on ${date}.</p>`,
          });

        } catch (stripeError) {
          // If the charge fails (e.g., expired card), we still record the failure.
          console.error(`Stripe charge failed for user ${user.id}:`, stripeError);
          // Send a "Payment Failed" email.
          await resend.emails.send({
            from: 'support@screenpledge.app',
            to: profile.email,
            subject: `Action Required: ScreenPledge Payment Failed for ${date}`,
            html: `<h1>Payment Failed</h1><p>Hi there, we were unable to process your pledge for ${date}. Please update your payment method in the app to maintain your accountability streak.</p>`,
          });
        }
      }

      // Atomically update the user's profile (reset streak).
      await supabaseAdmin.rpc('update_profile_on_failure', { user_id_input: user.id });

      // Insert the final, authoritative failure record.
      await supabaseAdmin.from('daily_results').insert({
        user_id: user.id,
        date: date,
        outcome: 'failure',
        pledge_charged_cents: chargedAmount,
        time_spent_seconds: final_usage_seconds,
        time_limit_seconds: timeLimit,
        timezone: timezone,
      });
    }

    // --- 6. RETURN SUCCESS RESPONSE ---
    return new Response(JSON.stringify({ message: 'Daily result processed successfully.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    // If any unexpected error occurs, log it and return a generic server error.
    console.error('Error in process-daily-result function:', error);
    return new Response(JSON.stringify({ error: 'An internal server error occurred.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

// NOTE: This function assumes you will create two small helper RPCs in your database
// for atomically updating the profile on success or failure. This is cleaner than
// putting complex UPDATE logic inside the Edge Function.
// You will need to create `update_profile_on_success` and `update_profile_on_failure`
// in the SQL Editor.