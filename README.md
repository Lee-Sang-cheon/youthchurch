# YouthChurch — 신앙 메타버스

청년부가 아바타로 모여 예배·소그룹·미니게임을 즐기는 Flutter 앱입니다.

## 주요 기능

- **인증**: 이메일 / 카카오 로그인, 닉네임·교회 설정
- **교회 홀**: 2D/3D(Three.js WebView) 예배당 씬, 실시간 presence
- **공간**: 예배실 · 기도실 · 소그룹 · 앨범 · 일정
- **미니게임**: 마피아, 끝말잇기, 라이어 게임, 양세찬 게임, 성경 퀴즈
- **백엔드**: Supabase (Auth, DB, Realtime, Edge Functions)

## 기술 스택

| 구분 | 기술 |
|------|------|
| 앱 | Flutter (Dart 3.12+), Riverpod |
| 게임/씬 | Flame, WebView + Three.js |
| 백엔드 | Supabase Flutter SDK |
| 소셜 로그인 | Kakao SDK, Google Sign-In |

## 시작하기

### 1. 저장소

```bash
git clone https://github.com/Lee-Sang-cheon/youthchurch.git
cd youthchurch
```

### 2. Supabase 설정

```bash
cp lib/core/supabase/supabase_config.example.dart \
   lib/core/supabase/supabase_config.dart
```

`supabase_config.dart`에 프로젝트 URL과 anon key를 넣습니다.  
이 파일은 `.gitignore`에 포함되어 커밋되지 않습니다.

### 3. 실행

```bash
flutter pub get
flutter run
```

### 4. (선택) Supabase Edge Functions / SQL

`supabase/` 아래에 마피아 게임·그룹 포스트 관련 SQL과 Edge Functions가 있습니다.  
로컬 또는 연결된 Supabase 프로젝트에 적용해 주세요.

## 디렉터리 구조

```
lib/
├── core/           # 테마, Glass 위젯, Supabase 설정
├── features/
│   ├── auth/       # 로그인 · 닉네임 · 교회 설정
│   ├── church/     # 홀 · 예배 · 소그룹 · 기도실 등
│   ├── home/       # 홈 · 챌린지
│   └── minigames/  # 마피아 · 끝말잇기 · 라이어 등
assets/             # Three.js 교회 씬 HTML 등
supabase/           # SQL 마이그레이션 · Edge Functions
```

## 기여하기

포크 후 PR로 기여해 주세요. 자세한 절차는 [CONTRIBUTING.md](./CONTRIBUTING.md)를 참고하세요.

## 라이선스

저장소에 라이선스 파일이 명시되어 있지 않습니다. 기여 전 메인테이너에게 확인해 주세요.
