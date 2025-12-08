// supabase/functions/process_free_notice/index.ts
// Xử lý free notices: pick cái có seq cao nhất pending
// Gửi nếu trong vòng 5 phút của send_after, rồi mark sent

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.3";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function processFreNotice() {
  try {
    console.log("[FreeNotice] Starting processor...");

    // Lấy notice pending có seq cao nhất
    const { data: notices, error } = await supabase
      .from("free_notices")
      .select("*")
      .eq("status", "pending")
      .order("seq", { ascending: false })
      .limit(1);

    if (error) {
      console.error("[FreeNotice] Query error:", error);
      return { status: "error", error };
    }

    if (!notices || notices.length === 0) {
      console.log("[FreeNotice] No pending notices");
      return { status: "no_pending" };
    }

    const notice = notices[0];
    const now = new Date().getTime();
    const sendAfter = new Date(notice.send_after).getTime();
    const diff = Math.abs(now - sendAfter);

    // Nếu trong vòng 5 phút (300000ms)
    if (diff <= 5 * 60 * 1000) {
      console.log(`[FreeNotice] Sending notice: ${notice.title}`);

      // Insert vào notification
      const { error: insertError } = await supabase
        .from("notification")
        .insert([
          {
            title: notice.title,
            message: notice.message,
            type: "free",
            url: "/",
          },
        ]);

      if (!insertError) {
        // Mark sent
        await supabase
          .from("free_notices")
          .update({ status: "sent" })
          .eq("id", notice.id);

        return { status: "success", sent: notice.title };
      } else {
        // Mark failed
        await supabase
          .from("free_notices")
          .update({ status: "failed" })
          .eq("id", notice.id);

        console.error("[FreeNotice] Insert error:", insertError);
        return { status: "error", error: insertError };
      }
    } else {
      console.log(`[FreeNotice] Not in 5min window yet (diff: ${diff}ms)`);
      return { status: "waiting", diff };
    }
  } catch (err) {
    console.error("[FreeNotice] Error:", err);
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

  // Check Authorization header
  const authHeader = req.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({
        code: 401,
        message: "Missing authorization header",
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        status: 401,
      }
    );
  }

  // Allow POST / GET with valid auth header
  if (req.method === "GET" || req.method === "POST") {
    const result = await processFreNotice();
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
