import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  const url = new URL(req.url)
  const token = url.searchParams.get('token')

  if (!token) return page('Invalid activation link.', false)

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  const { data: record } = await supabase
    .from('email_verifications')
    .select()
    .eq('token', token)
    .maybeSingle()

  if (!record) return page('This activation link is invalid or does not exist.', false)
  if (record.used_at) return page('This link has already been used. Please sign in to your account.', false)
  if (new Date(record.expires_at) < new Date()) {
    return page('This link has expired. Please sign in and request a new activation email.', false)
  }

  // Mark token used
  await supabase
    .from('email_verifications')
    .update({ used_at: new Date().toISOString() })
    .eq('token', token)

  // Activate the profile
  const { error: activateError } = await supabase
    .from('profiles')
    .update({ is_activated: true })
    .eq('id', record.user_id)

  if (activateError) {
    return page('Something went wrong activating your account. Please try again or contact support.', false)
  }

  return page('Your account has been activated! Open the app and sign in.', true)
})

function page(message: string, success: boolean): Response {
  const accent = success ? '#1A535C' : '#FF6B6B'
  const icon = success ? '✅' : '❌'
  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>MemoryMap — Account Activation</title>
</head>
<body style="font-family:-apple-system,sans-serif;background:#F7F3E9;display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0;padding:20px;box-sizing:border-box;">
  <div style="background:white;border-radius:24px;padding:48px 32px;max-width:400px;width:100%;text-align:center;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
    <div style="font-size:52px;margin-bottom:8px;">🗺️</div>
    <h1 style="color:#1A535C;font-size:24px;margin:0 0 4px;letter-spacing:-0.5px;">memorymap</h1>
    <p style="color:#aaa;font-style:italic;margin:0 0 32px;font-size:13px;">every place, a story.</p>
    <div style="font-size:48px;margin-bottom:16px;">${icon}</div>
    <p style="color:${accent};font-size:16px;font-weight:600;line-height:1.6;margin:0 0 12px;">${message}</p>
    ${success ? '<p style="color:#aaa;font-size:13px;margin:0;">You can close this page and open the MemoryMap app.</p>' : ''}
  </div>
</body>
</html>`
  return new Response(html, {
    headers: { 'Content-Type': 'text/html' },
    status: success ? 200 : 400,
  })
}
