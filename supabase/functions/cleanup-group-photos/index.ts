import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // 24시간 지난 포스트 조회
  const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()

  const { data: oldPosts, error } = await supabase
    .from('group_posts')
    .select('id, photo_url')
    .lt('created_at', cutoff)

  if (error) {
    return new Response(JSON.stringify({ ok: false, error: error.message }), { status: 500 })
  }

  if (!oldPosts || oldPosts.length === 0) {
    return new Response(JSON.stringify({ ok: true, deleted: 0 }))
  }

  // Storage에서 파일 삭제
  const paths = oldPosts
    .map((p) => {
      const url = p.photo_url as string
      // URL에서 버킷 이후 경로 추출
      const match = url.match(/group-photos\/(.+)/)
      return match ? match[1] : null
    })
    .filter(Boolean) as string[]

  if (paths.length > 0) {
    await supabase.storage.from('group-photos').remove(paths)
  }

  // DB에서 레코드 삭제
  const ids = oldPosts.map((p) => p.id as string)
  await supabase.from('group_posts').delete().in('id', ids)

  return new Response(JSON.stringify({ ok: true, deleted: ids.length }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
