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

    if (room?.phase !== 'voting' || room?.round !== round) {
      return new Response(JSON.stringify({ ok: false, reason: 'phase mismatch' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 낮 투표 조회
    const { data: votes } = await supabase
      .from('mafia_night_actions')
      .select('actor_id, target_id')
      .eq('room_id', room_id)
      .eq('round', round)
      .eq('action_type', 'day_vote')

    // 생존자 수
    const { data: alivePlayers } = await supabase
      .from('mafia_players')
      .select('user_id')
      .eq('room_id', room_id)
      .eq('is_alive', true)

    const totalAlive = alivePlayers?.length ?? 0
    const majority = Math.floor(totalAlive / 2) + 1

    // 투표 집계
    const tally: Record<string, number> = {}
    for (const vote of votes ?? []) {
      tally[vote.target_id] = (tally[vote.target_id] ?? 0) + 1
    }

    let executedUserId: string | null = null
    let executedNickname: string | null = null
    let executedRole: string | null = null

    // 과반수 득표자 처형
    for (const [uid, cnt] of Object.entries(tally)) {
      if (cnt >= majority) {
        executedUserId = uid
        break
      }
    }

    if (executedUserId) {
      const { data: player } = await supabase
        .from('mafia_players')
        .select('nickname, role')
        .eq('room_id', room_id)
        .eq('user_id', executedUserId)
        .single()

      executedNickname = player?.nickname ?? ''
      executedRole = player?.role ?? ''

      // 사망 처리
      await supabase
        .from('mafia_players')
        .update({ is_alive: false })
        .eq('room_id', room_id)
        .eq('user_id', executedUserId)

      // 게임 로그
      await supabase.from('mafia_game_logs').insert({
        room_id,
        round,
        event: 'executed',
        target_id: executedUserId,
        target_nickname: executedNickname,
        target_role: executedRole,
      })
    }

    // 승리 조건 체크
    const { data: allPlayers } = await supabase
      .from('mafia_players')
      .select('role, is_alive')
      .eq('room_id', room_id)

    const aliveMafia = allPlayers?.filter(p => p.is_alive && p.role === 'mafia').length ?? 0
    const aliveOthers = allPlayers?.filter(p => p.is_alive && p.role !== 'mafia').length ?? 0

    const newRound = round + 1

    if (aliveMafia === 0) {
      await supabase.from('mafia_rooms').update({
        phase: 'game_over',
        status: 'finished',
        phase_end_at: null,
        round: newRound,
      }).eq('id', room_id)
    } else if (aliveMafia >= aliveOthers) {
      await supabase.from('mafia_rooms').update({
        phase: 'game_over',
        status: 'finished',
        phase_end_at: null,
        round: newRound,
      }).eq('id', room_id)
    } else {
      // 라운드 결과 페이즈 (10초)
      const phaseEndAt = new Date(Date.now() + 10_000).toISOString()
      await supabase.from('mafia_rooms').update({
        phase: 'round_result',
        round: newRound,
        phase_end_at: phaseEndAt,
      }).eq('id', room_id)
    }

    return new Response(
      JSON.stringify({ ok: true, executed: executedNickname, role: executedRole }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
