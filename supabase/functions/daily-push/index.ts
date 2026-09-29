// Daily reminder pushes (see supabase/push.sql). Called once a day by the
// pg_cron job with the x-cron-secret header; sends what push_due() lists
// through Web Push and logs it so nothing goes out twice.
//
// Secrets (Edge Functions -> Secrets):
//   CRON_SECRET        same value as in the cron job
//   VAPID_PUBLIC_KEY   also given to the web build (--dart-define)
//   VAPID_PRIVATE_KEY  never leaves the server
//   VAPID_SUBJECT      mailto:you@example.com (contact for push services)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.
import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

type Msg = { title: string; body: string };

const KO: Record<string, Msg> = {
  inactive_1: { title: "오늘 기록 잊지 않으셨죠?", body: "대충이라도 괜찮아요. 한 끼만 넣어도 추정이 정확해져요." },
  inactive_3: { title: "3일 쉬셨네요", body: "오늘 한 끼만 기록해도 추세가 다시 이어져요." },
  inactive_7: { title: "일주일 만이에요", body: "체중만 재도 코칭이 다시 시작돼요." },
  inactive_14: { title: "다시 시작해 볼까요?", body: "목표 칼로리를 지금 몸에 맞게 다시 맞춰 드릴게요." },
  inactive_30: { title: "알아서핏이 기다리고 있어요", body: "언제든 돌아오시면 거기서부터 다시 맞춰 드려요. 이 알림은 마지막이에요." },
  checkin: { title: "오늘은 체크인 날이에요", body: "지난주 기록으로 이번 주 목표를 맞춰 드릴게요." },
};

const EN: Record<string, Msg> = {
  inactive_1: { title: "Log today?", body: "Even a rough entry keeps your estimate accurate." },
  inactive_3: { title: "3 days off", body: "Log one meal today and your trend picks up again." },
  inactive_7: { title: "It's been a week", body: "Just a weigh-in restarts your coaching." },
  inactive_14: { title: "Start again?", body: "We'll fit your calorie target to where you are now." },
  inactive_30: { title: "We're here when you're ready", body: "Come back anytime and we'll pick up from there. This is the last reminder." },
  checkin: { title: "Check-in day", body: "Last week's logs will tune this week's target." },
};

Deno.serve(async (req) => {
  if (req.headers.get("x-cron-secret") !== Deno.env.get("CRON_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }
  webpush.setVapidDetails(
    Deno.env.get("VAPID_SUBJECT")!,
    Deno.env.get("VAPID_PUBLIC_KEY")!,
    Deno.env.get("VAPID_PRIVATE_KEY")!,
  );
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: due, error } = await db.rpc("push_due");
  if (error) return new Response(error.message, { status: 500 });

  let sent = 0, gone = 0;
  for (const row of due ?? []) {
    const msg = (row.language === "en" ? EN : KO)[row.kind];
    if (!msg) continue;
    const { data: subs } = await db
      .from("push_subscriptions")
      .select("endpoint, p256dh, auth, platform")
      .eq("user_id", row.user_id);
    let delivered = false;
    for (const s of subs ?? []) {
      if (s.platform !== "web") continue; // FCM (apps) comes later
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          JSON.stringify({ ...msg, url: "./" }),
          { TTL: 60 * 60 * 12 },
        );
        delivered = true;
      } catch (e) {
        const code = (e as { statusCode?: number }).statusCode;
        if (code === 404 || code === 410) {
          // Unsubscribed or expired: forget this device.
          await db.from("push_subscriptions").delete().eq("endpoint", s.endpoint);
          gone++;
        } else {
          console.error("push failed", code, e);
        }
      }
    }
    if (delivered) {
      await db.from("push_log").insert({ user_id: row.user_id, kind: row.kind });
      sent++;
    }
  }
  return Response.json({ due: due?.length ?? 0, sent, gone });
});
