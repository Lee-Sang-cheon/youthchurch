import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { room_id, round } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 중복 실행 방지
    const { data: room } = await supabase
      .from('mafia_rooms')
      .select('phase, round')
      .eq('id', room_id)
      .single()

    if (room?.phase !== 'night' || room?.round !== round) {
      return new Response(JSON.stringify({ ok: false, reason: 'phase mismatch' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 이번 라운드 밤 행동 조회
    const { data: actions } = await supabase
      .from('mafia_night_actions')
      .select('*')
      .eq('room_id', room_id)
      .eq('round', round)

    const mafiaVotes = actions?.filter(a => a.action_type === 'mafia_vote') ?? []
    const doctorAction = actions?.find(a => a.action_type === 'doctor_protect')
    const policeAction = actions?.find(a => a.action_type === 'police_investigate')

    const protectedUserId: string | null = doctorAction?.target_id ?? null

    // 마피아 투표 집계
    const tally: Record<string, number> = {}
    for (const vote of mafiaVotes) {
      tally[vote.target_id] = (tally[vote.target_id] ?? 0) + 1
    }

    let killTargetUserId: string | null = null
    let maxVotes = 0
    for (const [uid, cnt] of Object.entries(tally)) {
      if (cnt > maxVotes) {
        maxVotes = cnt
        killTargetUserId = uid
      }
    }

    // 의사 보호 체크 & 처리
    if (killTargetUserId && killTargetUserId !== protectedUserId) {
      // 사망 처리
      await supabase
        .from('mafia_players')
        .update({ is_alive: false })
        .eq('room_id', room_id)
        .eq('user_id', killTargetUserId)

      // 닉네임 조회
      const { data: victim } = await supabase
        .from('mafia_players')
        .select('nickname')
        .eq('room_id', room_id)
        .eq('user_id', killTargetUserId)
        .single()

      // 게임 로그
      await supabase.from('mafia_game_logs').insert({
        room_id,
        round,
        event: 'killed',
        target_id: killTargetUserId,
        target_nickname: victim?.nickname ?? '',
      })
    } else if (killTargetUserId && killTargetUserId === protectedUserId) {
      // 의사가 보호함
      const { data: saved } = await supabase
        .from('mafia_players')
        .select('nickname')
        .eq('room_id', room_id)
        .eq('user_id', killTargetUserId)
        .single()

      await supabase.from('mafia_game_logs').insert({
        room_id,
        round,
        event: 'saved',
        target_id: killTargetUserId,
        target_nickname: saved?.nickname ?? '',
      })
    }

    // 경찰 조사 결과 저장
    if (policeAction) {
      const { data: target } = await supabase
        .from('mafia_players')
        .select('role')
        .eq('room_id', room_id)
        .eq('user_id', policeAction.target_id)
        .single()

      const result = target?.role === 'mafia' ? 'mafia' : 'citizen'
      await supabase
        .from('mafia_night_actions')
        .update({ result })
        .eq('id', policeAction.id)
    }

    // 승리 조건 체크
    const { data: allPlayers } = await supabase
      .from('mafia_players')
      .select('role, is_alive')
      .eq('room_id', room_id)

    const aliveMafia = allPlayers?.filter(p => p.is_alive && p.role === 'mafia').length ?? 0
    const aliveOthers = allPlayers?.filter(p => p.is_alive && p.role !== 'mafia').length ?? 0

    if (aliveMafia === 0) {
      // 시민 승리
      await supabase.from('mafia_rooms').update({
        phase: 'game_over',
        status: 'finished',
        phase_end_at: null,
      }).eq('id', room_id)
    } else if (aliveMafia >= aliveOthers) {
      // 마피아 승리
      await supabase.from('mafia_rooms').update({
        phase: 'game_over',
        status: 'finished',
        phase_end_at: null,
      }).eq('id', room_id)
    } else {
      // 낮 페이즈로 전환 (90초)
      const phaseEndAt = new Date(Date.now() + 90_000).toISOString()
      await supabase.from('mafia_rooms').update({
        phase: 'day',
        phase_end_at: phaseEndAt,
      }).eq('id', room_id)
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
