# 교회 메타버스 · 청년부 라운지 (Flutter)

은은하게 어두운 예배당을 배경으로, 청년들이 빛나는 아바타로 모이는 메타버스 라운지 앱입니다.
HTML 프로토타입(`교회 메타버스.html`)을 **네이티브 Flutter 위젯**으로 다시 구현했습니다. iOS / Android 모두에서 동작합니다.

## 실행 방법

```bash
# 1) 프로젝트 폴더로 이동
cd flutter_church_metaverse

# 2) (최초 1회) Flutter 프로젝트 스캐폴딩 생성 — android/ios/web 등 플랫폼 폴더가 없을 때
flutter create .

# 3) 패키지 설치
flutter pub get

# 4) 실행 (연결된 기기/시뮬레이터)
flutter run
```

> `lib/`, `pubspec.yaml` 만 들어있는 상태이므로, 플랫폼 폴더가 없다면 `flutter create .` 를 한 번 실행해 주세요.
> 기존 Flutter 프로젝트에 합치려면 `lib/` 안의 파일들을 복사하고 `pubspec.yaml` 의존성만 맞추면 됩니다.

## 파일 구조

| 파일 | 역할 |
|---|---|
| `lib/main.dart` | 앱 진입점 · 메인 셸(홀/예배/라운지 전환) · 상단 HUD · 하단 네비 · 채팅/나 패널 · 바닥 탭 이동 · 리액션 |
| `lib/church_scene.dart` | 예배당 배경 — 하늘 그라데이션, 스테인드글라스 창, 십자가, 빛기둥(godray), 원근 바닥, 떠다니는 먼지, 비네트 |
| `lib/avatars.dart` | 유저 아바타(머리/몸통/글로우/이름표/idle 애니메이션) · 내 아바타 · 룸 포털 · 프로필 바텀시트 |
| `lib/worship_screen.dart` | 예배 라이브 룸 — 무대 조명, 밴드 실루엣, 흐르는 가사, 리액션 |
| `lib/reactions.dart` | 떠오르는 리액션 이모지 위젯 |
| `lib/models.dart` | 유저 데이터 모델 · 더미 유저 |
| `lib/theme.dart` | 색상 토큰 (HTML CSS 변수와 1:1 대응) |
| `lib/glass.dart` | 글래스모피즘 컨테이너 · 깜빡이는 점 |

## 주요 인터랙션

- **바닥 탭** → 내 아바타가 그 자리로 부드럽게 이동
- **아바타 탭** → 프로필 카드(이름/역할/상태) + 👋🙏✨❤️ 인사 → 리액션이 위로 떠오름
- **룸 포털 탭** → 주일 청년예배 LIVE / 기도의 골방 / 소그룹 라운지 입장
- **하단 네비** → 홀 / 예배 / 소그룹 / 채팅 / 나

## 커스터마이징 팁

- 조명 색·유리 색감: `lib/theme.dart` 의 `AC.light`, `AC.glass1~3` 값만 바꾸면 전체 분위기가 바뀝니다.
- 유저 목록: `lib/models.dart` 의 `kUsers` 를 수정하세요.
- 아바타 스타일: `AvatarStyle.blob / figure / orb` (위젯 `style` 파라미터).

## 한글 폰트(Pretendard) 적용 — 선택

1. `assets/fonts/` 에 Pretendard `.otf` 파일을 넣습니다.
2. `pubspec.yaml` 의 `fonts:` 주석을 해제합니다.
3. `lib/main.dart` 의 `ThemeData(fontFamily: 'Pretendard')` 로 변경합니다.

## 참고

빛기둥 글로우·블러는 `ImageFiltered`, 글래스 UI는 `BackdropFilter` 로 구현되어 있습니다.
실기기에서 가장 자연스럽게 보이며, 일부 효과는 웹 빌드에서 성능 차이가 있을 수 있습니다.
