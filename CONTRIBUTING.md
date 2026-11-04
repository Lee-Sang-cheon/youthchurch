# Contributing to YouthChurch

포크 기반 기여를 환영합니다.

## 워크플로

1. **Fork** — [Lee-Sang-cheon/youthchurch](https://github.com/Lee-Sang-cheon/youthchurch)를 본인 계정으로 포크
2. **Clone & remotes**

   ```bash
   gh repo clone <your-username>/youthchurch
   cd youthchurch
   git remote add upstream https://github.com/Lee-Sang-cheon/youthchurch.git
   ```

3. **Sync** — 작업 전 upstream `main`을 맞춥니다

   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   git push origin main
   ```

4. **Branch** — 짧은 목적의 브랜치를 만듭니다

   ```bash
   git checkout -b feat/short-description
   # 또는 fix/..., docs/...
   ```

5. **Commit** — 관련 변경만, 커밋 메시지는 무엇을/왜를 짧게
6. **Push & PR** — 업스트림으로 PR을 엽니다

   ```bash
   git push -u origin HEAD
   gh pr create -R Lee-Sang-cheon/youthchurch \
     --head <your-username>:<branch> \
     --title "..." --body "..."
   ```

## PR 가이드

- 한 PR = 한 목적 (문서 / 버그픽스 / 기능 분리)
- UI 변경이면 스크린샷 또는 짧은 동작을 본문에 포함
- `lib/core/supabase/supabase_config.dart` 등 시크릿은 커밋하지 말 것
- 가능하면 `flutter analyze` 후 제출

## 로컬 체크

```bash
flutter pub get
flutter analyze
# 기기/에뮬레이터에서
flutter run
```

## 질문이 있을 때

업스트림 [Issues](https://github.com/Lee-Sang-cheon/youthchurch/issues)에 먼저 이슈를 열어 범위와 방향을 맞춰 주세요.
