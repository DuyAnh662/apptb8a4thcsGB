// supabase/functions/send_daily_notification/index.ts
// Gửi thông báo hằng ngày (19:00 UTC+7 = 12:00 UTC)
// Tóm tắt TKB hôm nay + BTVN thành 1 thông báo

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.3";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function sendDailyNotification() {
  try {
    console.log("[Daily] Starting daily notification...");

    // Lấy data TKB + BTVN
    const [tkbRes, btvnRes] = await Promise.all([
      supabase.from("tkb").select("*"),
      supabase.from("btvn").select("*"),
    ]);

    const tkb = tkbRes.data || [];
    const btvn = btvnRes.data || [];

    // Tính ngày hôm nay (theo logic script.js)
    // Nếu sau 16:00 UTC+7 thì lấy ngày mai
    const now = new Date();
    const nowUTC7 = new Date(now.getTime() + 420 * 60000); // UTC+7
    let day = nowUTC7.getDay(); // 0=Sunday, 1=Monday, ...
    
    if (nowUTC7.getHours() >= 16) {
      day++;
    }
    if (day >= 6 || day === 0) {
      day = 1; // Convert Sat/Sun to Mon
    }

    console.log(`[Daily] Computing for day: ${day}`);

    // Lấy môn học hôm nay
    const subjects = [...new Set(
      tkb
        .filter((i) => Number(i.day) === day)
        .map((i) => (i.subject || "").toLowerCase())
    )];

    if (!subjects.length) {
      console.log("[Daily] No subjects today");
      return { status: "no_subjects" };
    }

    // Build thông báo
    const mhkNoHomework = [];
    const withHomework = [];

    for (const subject of subjects) {
      const items = btvn.filter((b) =>
        (b.subject || "").toLowerCase().includes(subject)
      );
      const contents = items.map((it) => it.content || it.note || "").filter(Boolean);

      if (!contents.length || contents.some((c) => c.includes("Không có bài tập"))) {
        mhkNoHomework.push(subject);
      } else {
        withHomework.push({ subject, content: contents.join(" | ") });
      }
    }

    let message = "Chào bạn! ";
    if (mhkNoHomework.length) {
      message += `Hôm nay có môn ${mhkNoHomework.join(", ")} không có bài tập. `;
    }
    if (withHomework.length) {
      message += `Các môn có bài tập: ${withHomework.map((x) => x.subject).join(", ")}.`;
    }

    // Insert vào notification
    const { data, error } = await supabase
      .from("notification")
      .insert([
        {
          title: "📚 Bài tập hôm nay",
          message,
          type: "daily",
          url: "/",
        },
      ]);

    if (error) {
      console.error("[Daily] Insert error:", error);
      return { status: "error", error };
    }

    console.log("[Daily] Success!", data);
    return { status: "success", data };
  } catch (err) {
    console.error("[Daily] Error:", err);
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
    const result = await sendDailyNotification();
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
