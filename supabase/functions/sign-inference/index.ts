// Supabase Edge Function: sign language inference against the active ml_models row.
// Deploy: supabase functions deploy sign-inference
// No service_role key is embedded in the Flutter client — call with the user JWT (anon key).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";

    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: model, error: modelError } = await supabase
      .from("ml_models")
      .select("id, name, version, dataset, status")
      .eq("is_active", true)
      .maybeSingle();

    if (modelError) {
      return json(
        {
          ok: false,
          error: "model_lookup_failed",
          message: modelError.message,
        },
        503,
      );
    }

    if (!model || model.status !== "ready") {
      return json(
        {
          ok: false,
          error: "no_active_model",
          message:
            "No active ready model. Ask an admin to activate one, or try again later.",
        },
        503,
      );
    }

    // Model serving is not wired into this function yet. Never fabricate a
    // label: the client turns this into a "translation unavailable" state.
    return json(
      {
        ok: false,
        error: "inference_not_available",
        message: "Sign recognition is not served by this function yet.",
        model: {
          id: model.id,
          name: model.name,
          version: model.version,
          dataset: model.dataset,
        },
      },
      503,
    );
  } catch (e) {
    return json(
      {
        ok: false,
        error: "inference_failed",
        message: e instanceof Error ? e.message : String(e),
      },
      500,
    );
  }
});

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
