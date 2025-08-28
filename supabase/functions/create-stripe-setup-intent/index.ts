import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient, SupabaseClientOptions } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@11.1.0';
import { corsHeaders } from '../_shared/cors.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // =================================================================================
    // --- DIAGNOSTIC LOGGING BLOCK ---
    // This block will print the state of the environment variables to your function logs.
    console.log('--- NEW INVOCATION ---');
    
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');

    console.log('DIAGNOSTIC: SUPABASE_URL EXISTS:', !!Deno.env.get('SUPABASE_URL'));
    console.log('DIAGNOSTIC: SUPABASE_ANON_KEY EXISTS:', !!anonKey);
    console.log('DIAGNOSTIC: ANON_KEY LENGTH:', anonKey?.length ?? 0);
    console.log('DIAGNOSTIC: STRIPE_SECRET_KEY EXISTS:', !!stripeKey);
    console.log('DIAGNOSTIC: STRIPE_KEY LENGTH:', stripeKey?.length ?? 0);
    
    // This is the most critical log.
    console.log('DIAGNOSTIC: SUPABASE_SERVICE_ROLE_KEY EXISTS:', !!serviceRoleKey);
    console.log('DIAGNOSTIC: SERVICE_ROLE_KEY LENGTH:', serviceRoleKey?.length ?? 0);
    console.log('--- END DIAGNOSTIC LOGS ---');
    // =================================================================================

    const adminAuthClientOptions: SupabaseClientOptions<"public"> = {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    };

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      serviceRoleKey!, // Use the variable we captured for logging
      adminAuthClientOptions
    );

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      throw new Error('User not found');
    }

    console.log(`Function invoked for user: ${user.id}`);

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single();

    // If there's an error here, it will be logged by the catch block.
    if (profileError) throw profileError;

    let customerId = profile?.stripe_customer_id;

    if (!customerId) {
      console.log(`No Stripe customer found for user ${user.id}. Creating one.`);
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_user_id: user.id },
      });
      customerId = customer.id;

      const { error: updateError } = await supabaseAdmin
        .from('profiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id);

      if (updateError) throw updateError;
      console.log(`Stripe customer ${customerId} created and saved for user ${user.id}.`);
    } else {
      console.log(`Existing Stripe customer ${customerId} found for user ${user.id}.`);
    }

    const setupIntent = await stripe.setupIntents.create({
      customer: customerId,
    });

    console.log(`Setup Intent created for customer ${customerId}.`);

    return new Response(
      JSON.stringify({ client_secret: setupIntent.client_secret }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    // Enhanced error logging
    console.error('--- CATCH BLOCK ERROR ---');
    console.error('Error Message:', error.message);
    console.error('Full Error Object:', error);
    console.error('--- END CATCH BLOCK ---');
    
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});