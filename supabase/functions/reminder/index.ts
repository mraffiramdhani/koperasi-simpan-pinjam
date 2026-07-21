import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { sendPush } from '../_shared/fcm.ts';

// Dipanggil terjadwal (mis. via pg_cron + pg_net) untuk:
// 1) Membuat reminder in-app (generate_due_reminders)
// 2) Mengirim push FCM untuk reminder hari ini
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1) Hasilkan reminder in-app
    await admin.rpc('generate_due_reminders');

    // 2) Kirim push untuk notifikasi angsuran yang dibuat hari ini
    const today = new Date().toISOString().slice(0, 10);
    const { data: notifs } = await admin
      .from('notifications')
      .select('judul, isi, members!inner(fcm_token)')
      .eq('tipe', 'angsuran')
      .gte('created_at', `${today}T00:00:00Z`);

    let sent = 0;
    for (const n of notifs ?? []) {
      const token = (n.members as { fcm_token: string | null } | null)?.fcm_token;
      if (token) {
        const ok = await sendPush(token, n.judul as string, n.isi as string);
        if (ok) sent++;
      }
    }

    return jsonResponse({ ok: true, push_sent: sent });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
