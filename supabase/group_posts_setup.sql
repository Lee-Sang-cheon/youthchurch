-- 소그룹 사진 포스트 테이블
CREATE TABLE IF NOT EXISTS group_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cell_group_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT NOT NULL,
  photo_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE group_posts ENABLE ROW LEVEL SECURITY;

-- 같은 소그룹 멤버만 조회
CREATE POLICY "같은 소그룹 멤버 조회" ON group_posts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM cell_group_members
      WHERE cell_group_id = group_posts.cell_group_id
        AND user_id = auth.uid()
    )
  );

-- 본인만 업로드
CREATE POLICY "본인 포스트 등록" ON group_posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 본인만 삭제
CREATE POLICY "본인 포스트 삭제" ON group_posts
  FOR DELETE USING (auth.uid() = user_id);

-- Realtime 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE group_posts;
ALTER TABLE group_posts REPLICA IDENTITY FULL;

-- Storage 버킷 생성 (대시보드에서 직접 생성 권장)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('group-photos', 'group-photos', true)
-- ON CONFLICT DO NOTHING;
