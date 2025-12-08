// supabase/functions/cleanup_notifications/index.ts
// Xóa notifications cũ (>30 ngày) để tiết kiệm storage

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.3";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function cleanupNotifications() {
  try {
    console.log("[Cleanup] Starting cleanup...");

    // Xóa notification cũ hơn 30 ngày
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30);

    const { count, error } = await supabase
      .from("notification")
      .delete()
      .lt("created_at", cutoffDate.toISOString());

    if (error) {
      console.error("[Cleanup] Delete error:", error);
      return { status: "error", error };
    }

    console.log(`[Cleanup] Deleted ${count} old notifications`);

    // Optionally: reset counters hoặc cleanup free_notices cũ
    // const { count: freeCleanup } = await supabase
    //   .from("free_notices")
    //   .delete()
    //   .lt("created_at", cutoffDate.toISOString());

    return { status: "success", cleaned: count };
  } catch (err) {
    console.error("[Cleanup] Error:", err);
    return { status: "error", error: String(err) };
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  // Allow POST / GET without auth
  if (req.method === "GET" || req.method === "POST") {
    const result = await cleanupNotifications();
    return new Response(JSON.stringify(result), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      status: 200,
    });
  }
  return new Response("Method Not Allowed", { status: 405 });
});
