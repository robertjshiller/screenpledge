// These are the standard CORS headers for allowing your Flutter app
// to communicate with the Supabase Edge Function.
export const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };