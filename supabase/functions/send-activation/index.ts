import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

function generateToken(): string {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('')
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const { userId, email, name } = await req.json()
  if (!userId || !email) {
    return new Response(JSON.stringify({ error: 'Missing userId or email' }), { status: 400 })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  // Generate secure token and store it
  const token = generateToken()
  const activationUrl = `${SUPABASE_URL}/functions/v1/activate?token=${token}`

  const { error: dbError } = await supabase.from('email_verifications').insert({
    token,
    user_id: userId,
    email,
    name: name ?? null,
  })

  if (dbError) {
    return new Response(JSON.stringify({ error: dbError.message }), { status: 500 })
  }

  // Send email via Resend
  const emailRes = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'MemoryMap <onboarding@resend.dev>',
      to: email,
      subject: 'Activate your MemoryMap account',
      html: `
        <div style="font-family:-apple-system,sans-serif;max-width:480px;margin:0 auto;padding:40px 24px;background:#F7F3E9;">
          <div style="background:white;border-radius:24px;padding:40px 32px;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
            <div style="text-align:center;margin-bottom:28px;">
              <div style="font-size:52px;">🗺️</div>
              <h1 style="color:#1A535C;font-size:26px;margin:8px 0 4px;letter-spacing:-1px;">memorymap</h1>
              <p style="color:#aaa;font-style:italic;margin:0;font-size:13px;">every place, a story.</p>
            </div>
            <h2 style="color:#1A1A2E;font-size:20px;margin:0 0 12px;">Hi ${name ?? 'there'} 👋</h2>
            <p style="color:#555;font-size:15px;line-height:1.7;margin:0 0 28px;">
              Welcome to MemoryMap! Click the button below to activate your account and start pinning your memories to the map.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="${activationUrl}"
                style="background:#1A535C;color:white;padding:16px 40px;text-decoration:none;border-radius:12px;font-weight:700;font-size:16px;display:inline-block;">
                Activate My Account
              </a>
            </div>
            <p style="color:#bbb;font-size:12px;text-align:center;margin:0;">
              This link expires in 24 hours. If you didn't create this account, you can ignore this email.
            </p>
          </div>
        </div>
      `,
    }),
  })

  if (!emailRes.ok) {
    const errText = await emailRes.text()
    return new Response(JSON.stringify({ error: errText }), { status: 500 })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
