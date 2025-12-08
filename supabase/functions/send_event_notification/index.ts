// supabase/functions/send_event_notification/index.ts
// Gửi thông báo sự kiện (00:00 UTC+7 = 17:00 UTC prev day)
// Kiểm tra bảng `events` nếu hôm nay có sự kiện thì gửi

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.3";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function sendEventNotification() {
  try {
    console.log("[Event] Starting event check...");

    // Ngày hôm nay (DD/MM)
    const now = new Date();
    const day = String(now.getDate()).padStart(2, "0");
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const dateStr = `${day}/${month}`; // e.g. "24/12"

    console.log(`[Event] Checking for date: ${dateStr}`);

    // Lấy events của hôm nay
    const { data: events, error } = await supabase
      .from("events")
      .select("*")
      .eq("date", dateStr)
      .eq("is_sent", false);

    if (error) {
      console.error("[Event] Query error:", error);
      return { status: "error", error };
    }

    if (!events || events.length === 0) {
      console.log("[Event] No events today");
      return { status: "no_events" };
    }

    // Gửi notification cho mỗi event
    for (const event of events) {
      const { error: insertError } = await supabase
        .from("notification")
        .insert([
          {
            title: event.title,
            message: event.message,
            type: "event",
            url: "/",
          },
        ]);

      if (!insertError) {
        // Mark as sent
        await supabase.from("events").update({ is_sent: true }).eq("id", event.id);
        console.log(`[Event] Sent: ${event.title}`);
      } else {
        console.error(`[Event] Insert error for ${event.title}:`, insertError);
      }
    }

    return { status: "success", sent: events.length };
  } catch (err) {
    console.error("[Event] Error:", err);
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
    const result = await sendEventNotification();
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
