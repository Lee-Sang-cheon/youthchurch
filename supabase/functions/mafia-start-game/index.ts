import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

function assignRoles(count: number): string[] {
  const config: Record<string, number> = (() => {
    switch (count) {
      case 1:  return { mafia: 1 }
      case 2:  return { citizen: 1, mafia: 1 }
      case 3:  return { citizen: 2, mafia: 1 }
      case 4:  return { citizen: 3, mafia: 1 }
      case 5:  return { citizen: 3, mafia: 1, police: 1 }
      case 6:  return { citizen: 3, mafia: 2, police: 1 }
      case 7:  return { citizen: 3, mafia: 2, police: 1, doctor: 1 }
      case 8:  return { citizen: 4, mafia: 2, police: 1, doctor: 1 }
      case 9:  return { citizen: 4, mafia: 3, police: 1, doctor: 1 }
      default: return { citizen: 5, mafia: 3, police: 1, doctor: 1 }
    }
  })()
  const roles: string[] = []
  for (const [role, n] of Object.entries(config)) {
    for (let i = 0; i < n; i++) roles.push(role)
  }
  for (let i = roles.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [roles[i], roles[j]] = [roles[j], roles[i]]
  }
  return roles
}

serve(async (req) => {
  try {
    const { room_id } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: room } = await supabase
      .from('mafia_rooms')
      .select('phase, status')
      .eq('id', room_id)
      .single()

    if (room?.phase !== 'lobby') {
      return new Response(JSON.stringify({ ok: false, reason: 'already started' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: players, error: playersErr } = await supabase
      .from('mafia_players')
      .select('id, user_id')
      .eq('room_id', room_id)

    if (playersErr || !players || players.length < 1) {
      return new Response(JSON.stringify({ ok: false, reason: 'not enough players' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const roles = assignRoles(players.length)
    const mafiaUserIds: string[] = []

    for (let i = 0; i < players.length; i++) {
      if (roles[i] === 'mafia') mafiaUserIds.push(players[i].user_id)
    }

    for (let i = 0; i < players.length; i++) {
      const isMafia = roles[i] === 'mafia'
      await supabase
        .from('mafia_players')
        .update({
          role: roles[i],
          mafia_uids: isMafia ? mafiaUserIds : null,
        })
        .eq('id', players[i].id)
    }

    const phaseEndAt = new Date(Date.now() + 30_000).toISOString()
    await supabase
      .from('mafia_rooms')
      .update({
        phase: 'role_reveal',
        status: 'playing',
        round: 1,
        phase_end_at: phaseEndAt,
      })
      .eq('id', room_id)

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
