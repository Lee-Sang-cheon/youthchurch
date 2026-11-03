-- =============================================
-- 마피아 게임 Supabase 설정



-- Supabase Dashboard > SQL Editor에서 실행하세요
-- =============================================

-- 1. 테이블 생성
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS mafia_rooms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT NOT NULL UNIQUE,
  host_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status      TEXT NOT NULL DEFAULT 'waiting',   -- waiting | playing | finished
  phase       TEXT NOT NULL DEFAULT 'lobby',     -- lobby | role_reveal | night | day | voting | round_result | game_over
  phase_end_at TIMESTAMPTZ,
  round       INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mafia_players (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id     UUID REFERENCES mafia_rooms(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname    TEXT NOT NULL,
  role        TEXT,               -- citizen | mafia | police | doctor (null until game starts)
  is_alive    BOOLEAN NOT NULL DEFAULT TRUE,
  mafia_uids  JSONB,              -- 마피아 플레이어만: 동료 마피아 user_id 배열
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

CREATE TABLE IF NOT EXISTS mafia_night_actions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id     UUID REFERENCES mafia_rooms(id) ON DELETE CASCADE,
  round       INTEGER NOT NULL,
  actor_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,   -- mafia_vote | police_investigate | doctor_protect | day_vote
  result      TEXT,            -- 경찰 조사 결과: 'mafia' | 'citizen'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, round, actor_id, action_type)
);

CREATE TABLE IF NOT EXISTS mafia_chat_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id     UUID REFERENCES mafia_rooms(id) ON DELETE CASCADE,
  sender_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname    TEXT NOT NULL,
  content     TEXT NOT NULL,
  chat_type   TEXT NOT NULL DEFAULT 'public',   -- public | mafia
  round       INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mafia_game_logs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id          UUID REFERENCES mafia_rooms(id) ON DELETE CASCADE,
  round            INTEGER NOT NULL,
  event            TEXT NOT NULL,           -- killed | executed | saved
  target_id        UUID,
  target_nickname  TEXT,
  target_role      TEXT,                    -- executed 이벤트에서만 공개
  created_at       TIMESTAMPTZ DEFAULT NOW()
);


-- 2. Realtime 활성화
-- ─────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE mafia_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE mafia_players;
ALTER PUBLICATION supabase_realtime ADD TABLE mafia_chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE mafia_game_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE mafia_night_actions;

-- Realtime Postgres Changes에 필요한 설정
ALTER TABLE mafia_rooms        REPLICA IDENTITY FULL;
ALTER TABLE mafia_players      REPLICA IDENTITY FULL;
ALTER TABLE mafia_chat_messages REPLICA IDENTITY FULL;
ALTER TABLE mafia_game_logs    REPLICA IDENTITY FULL;
ALTER TABLE mafia_night_actions REPLICA IDENTITY FULL;


-- 3. Row Level Security
-- ─────────────────────────────────────────────

-- mafia_rooms
ALTER TABLE mafia_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "인증된 사용자는 대기 중인 방 조회 가능" ON mafia_rooms
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "인증된 사용자는 방 생성 가능" ON mafia_rooms
  FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE POLICY "방장만 방 업데이트 가능" ON mafia_rooms
  FOR UPDATE USING (auth.uid() = host_id);

-- mafia_players
ALTER TABLE mafia_players ENABLE ROW LEVEL SECURITY;

CREATE POLICY "같은 방 플레이어 조회 가능" ON mafia_players
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM mafia_players mp
      WHERE mp.room_id = mafia_players.room_id
        AND mp.user_id = auth.uid()
    )
  );

CREATE POLICY "본인 플레이어 등록 가능" ON mafia_players
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "본인 플레이어 수정 가능" ON mafia_players
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "본인 플레이어 삭제 가능" ON mafia_players
  FOR DELETE USING (auth.uid() = user_id);

-- mafia_night_actions
ALTER TABLE mafia_night_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "본인 행동만 조회 가능 (투표 제외)" ON mafia_night_actions
  FOR SELECT USING (
    auth.uid() = actor_id
    OR action_type = 'day_vote'  -- 낮 투표는 공개
  );

CREATE POLICY "본인 행동만 등록 가능" ON mafia_night_actions
  FOR INSERT WITH CHECK (auth.uid() = actor_id);

CREATE POLICY "본인 행동만 수정 가능" ON mafia_night_actions
  FOR UPDATE USING (auth.uid() = actor_id);

-- mafia_chat_messages
ALTER TABLE mafia_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "공개 채팅 조회 가능" ON mafia_chat_messages
  FOR SELECT USING (
    chat_type = 'public'
    OR (
      chat_type = 'mafia'
      AND EXISTS (
        SELECT 1 FROM mafia_players
        WHERE room_id = mafia_chat_messages.room_id
          AND user_id = auth.uid()
          AND role = 'mafia'
      )
    )
  );

CREATE POLICY "공개 채팅: 생존 시민만 전송" ON mafia_chat_messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND (
      chat_type = 'public'
      OR (
        chat_type = 'mafia'
        AND EXISTS (
          SELECT 1 FROM mafia_players
          WHERE room_id = mafia_chat_messages.room_id
            AND user_id = auth.uid()
            AND role = 'mafia'
        )
      )
    )
  );

-- mafia_game_logs
ALTER TABLE mafia_game_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "같은 방 플레이어는 게임 로그 조회 가능" ON mafia_game_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM mafia_players
      WHERE room_id = mafia_game_logs.room_id
        AND user_id = auth.uid()
    )
  );


-- 4. 인덱스
-- ─────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_mafia_players_room ON mafia_players(room_id);
CREATE INDEX IF NOT EXISTS idx_mafia_players_user ON mafia_players(user_id);
CREATE INDEX IF NOT EXISTS idx_mafia_actions_room_round ON mafia_night_actions(room_id, round);
CREATE INDEX IF NOT EXISTS idx_mafia_chat_room ON mafia_chat_messages(room_id, created_at);
CREATE INDEX IF NOT EXISTS idx_mafia_logs_room_round ON mafia_game_logs(room_id, round);


-- 5. Edge Function 배포 (터미널에서 실행)
-- ─────────────────────────────────────────────
-- supabase functions deploy mafia-start-game
-- supabase functions deploy mafia-night-resolve
-- supabase functions deploy mafia-vote-resolve
