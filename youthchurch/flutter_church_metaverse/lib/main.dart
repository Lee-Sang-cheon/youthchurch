import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'glass.dart';
import 'models.dart';
import 'church_scene.dart';
import 'avatars.dart';
import 'worship_screen.dart';
import 'reactions.dart';

void main() => runApp(const ChurchMetaverseApp());

class ChurchMetaverseApp extends StatelessWidget {
  const ChurchMetaverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '교회 메타버스',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AC.bgBot,
        // 한글 폰트 사용 시 pubspec 주석 해제 후 fontFamily: 'Pretendard'
        fontFamily: null,
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppView _view = AppView.hall;
  double _selfX = 50, _selfY = 8;
  final List<ReactionItem> _reactions = [];
  int _rid = 0;
  final _rand = math.Random();

  void _greet(AvatarUser u, String emoji) {
    final id = ++_rid;
    setState(() => _reactions.add(ReactionItem(id, emoji, u.x, u.y + 14, (_rand.nextDouble() - 0.5) * 60)));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AC.glassFill,
        margin: const EdgeInsets.only(bottom: 150, left: 40, right: 40),
        duration: const Duration(milliseconds: 2000),
        content: Text('${u.name}님에게 $emoji 인사를 보냈어요', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ));
  }

  void _move(TapDownDetails d, double w, double h, double floorH) {
    final px = (d.localPosition.dx / w) * 100;
    final py = ((floorH - d.localPosition.dy) / h) * 100;
    setState(() {
      _selfX = px.clamp(8.0, 92.0);
      _selfY = py.clamp(5.0, 34.0);
    });
  }

  void _enterRoom(String id) {
    if (id == 'worship') {
      setState(() => _view = AppView.worship);
    } else if (id == 'lounge') {
      setState(() => _view = AppView.lounge);
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AC.glassFill,
          margin: EdgeInsets.only(bottom: 150, left: 40, right: 40),
          content: Text('기도의 골방에 입장했어요 🙏', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _view == AppView.worship
          ? WorshipScreen(onBack: () => setState(() => _view = AppView.hall))
          : LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final floorH = h * 0.4;
                final users = _view == AppView.lounge ? loungeUsers() : kUsers;
                return Stack(
                  children: [
                    const Positioned.fill(child: ChurchScene(godrays: true)),

                    // 바닥 탭 → 이동
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: floorH,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _move(d, w, h, floorH),
                      ),
                    ),

                    // 다른 유저 아바타
                    for (var i = 0; i < users.length; i++)
                      Positioned(
                        left: users[i].x / 100 * w - 27,
                        bottom: users[i].y / 100 * h,
                        child: AvatarFigure(
                          user: users[i],
                          seed: i + 1,
                          onTap: () => showProfileSheet(context, users[i], _greet),
                        ),
                      ),

                    // 룸 포털 (홀에서만)
                    if (_view == AppView.hall) ..._portals(w, h),

                    // 내 아바타
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      left: _selfX / 100 * w - 27,
                      bottom: _selfY / 100 * h,
                      child: const SelfAvatar(),
                    ),

                    // 리액션
                    ..._reactions.map((r) => Positioned(
                          left: r.left / 100 * w,
                          bottom: r.bottom / 100 * h,
                          child: FloatingReaction(
                            emoji: r.emoji,
                            drift: r.drift,
                            onEnd: () => setState(() => _reactions.removeWhere((x) => x.id == r.id)),
                          ),
                        )),

                    // 상단 HUD
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                          child: _TopHud(
                            space: _view == AppView.lounge ? '소그룹 라운지' : '청년부 라운지',
                            count: _view == AppView.lounge ? 18 : 42,
                            onProfile: () => _showPanel(context, 'me'),
                          ),
                        ),
                      ),
                    ),

                    // 힌트 / 배너
                    if (_view == AppView.hall)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 110,
                        child: Center(
                          child: Text('바닥을 탭하면 이동해요 · 아바타를 탭해 인사하기',
                              style: TextStyle(fontSize: 11.5, color: AC.muted, shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)])),
                        ),
                      ),
                    if (_view == AppView.lounge)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 110,
                        child: Glass(
                          radius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('2셀 · 수요 나눔', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                              SizedBox(height: 1),
                              Text('지금 5명이 모여있어요', style: TextStyle(fontSize: 11, color: AC.muted)),
                            ],
                          ),
                        ),
                      ),

                    // 하단 네비
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: _BottomNav(
                            active: _view,
                            onNav: (id) {
                              if (id == 'chat' || id == 'me') {
                                _showPanel(context, id);
                              } else if (id == 'worship') {
                                setState(() => _view = AppView.worship);
                              } else if (id == 'lounge') {
                                setState(() => _view = AppView.lounge);
                              } else {
                                setState(() => _view = AppView.hall);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  List<Widget> _portals(double w, double h) {
    final rooms = [
      {'id': 'prayer', 'label': '기도의 골방', 'sub': '조용히 머무는 곳', 'x': 20.0, 'y': 37.0, 'hue': AC.glass1, 'live': false},
      {'id': 'worship', 'label': '주일 청년예배', 'sub': 'LIVE · 128명', 'x': 50.0, 'y': 41.0, 'hue': AC.light, 'live': true},
      {'id': 'lounge', 'label': '소그룹 라운지', 'sub': '셀모임 · 12개 방', 'x': 79.0, 'y': 38.0, 'hue': AC.glass2, 'live': false},
    ];
    return [
      for (final r in rooms)
        Positioned(
          left: (r['x'] as double) / 100 * w - 40,
          bottom: (r['y'] as double) / 100 * h,
          child: RoomPortal(
            label: r['label'] as String,
            sub: r['sub'] as String,
            hue: r['hue'] as Color,
            live: r['live'] as bool,
            onTap: () => _enterRoom(r['id'] as String),
          ),
        ),
    ];
  }

  void _showPanel(BuildContext context, String kind) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73040208),
      isScrollControlled: true,
      builder: (ctx) => kind == 'chat' ? const _ChatPanel() : const _MePanel(),
    );
  }
}

// ───────────────────── 상단 HUD ─────────────────────
class _TopHud extends StatelessWidget {
  final String space;
  final int count;
  final VoidCallback onProfile;
  const _TopHud({required this.space, required this.count, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Glass(
          radius: 999,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PulseDot(color: AC.online, size: 8),
              const SizedBox(width: 8),
              Text(space, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 8),
              Container(width: 1, height: 13, color: Colors.white.withOpacity(0.2)),
              const SizedBox(width: 8),
              Text.rich(TextSpan(
                style: const TextStyle(fontSize: 12, color: AC.muted),
                children: [
                  const TextSpan(text: '접속 '),
                  TextSpan(text: '$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              )),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onProfile,
          child: Glass(
            radius: 999,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFF5DC), Color(0xFFFFB24D)]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────── 하단 네비 ─────────────────────
class _BottomNav extends StatelessWidget {
  final AppView active;
  final void Function(String) onNav;
  const _BottomNav({required this.active, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'hall', 'label': '홀', 'icon': Icons.home_rounded},
      {'id': 'worship', 'label': '예배', 'icon': Icons.church},
      {'id': 'lounge', 'label': '소그룹', 'icon': Icons.groups_rounded},
      {'id': 'chat', 'label': '채팅', 'icon': Icons.chat_bubble_rounded},
      {'id': 'me', 'label': '나', 'icon': Icons.person_rounded},
    ];
    String activeId = active == AppView.hall ? 'hall' : active == AppView.lounge ? 'lounge' : 'worship';
    return Glass(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final it in items)
            _NavItem(
              label: it['label'] as String,
              icon: it['icon'] as IconData,
              active: (it['id'] as String) == activeId,
              onTap: () => onNav(it['id'] as String),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0x80ECE9FF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? AC.glow(0.5) : color,
                shadows: active ? [Shadow(color: AC.glow(0.8), blurRadius: 10)] : null),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── 채팅 패널 ─────────────────────
class _ChatPanel extends StatelessWidget {
  const _ChatPanel();

  @override
  Widget build(BuildContext context) {
    final chat = [
      {'u': '민재', 'c': '오늘 셀모임 8시 라운지에서 봬요!', 'color': const Color(0xFFFFA14D)},
      {'u': '서연', 'c': '처음이라 떨리네요 잘 부탁드려요 🙏', 'color': const Color(0xFFFF7EB6)},
      {'u': '지수', 'c': '찬양팀 사운드체크 들어갑니다', 'color': const Color(0xFF7C5CFF)},
      {'u': '하은', 'c': '라이브 송출 곧 시작할게요 🎥', 'color': const Color(0xFF5B9DFF)},
    ];
    return _PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('청년부 라운지 채팅', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 14),
          for (final m in chat) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: m['color'] as Color)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['u'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(m['c'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFFDED8F5), height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 2),
          Glass(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('메시지 보내기…', style: TextStyle(fontSize: 13, color: AC.muted)),
                Icon(Icons.send_rounded, size: 18, color: AC.glow(0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── 나 패널 ─────────────────────
class _MePanel extends StatelessWidget {
  const _MePanel();

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFF5DC), Color(0xFFFFB24D)]),
              boxShadow: [BoxShadow(color: AC.light.withOpacity(0.4), blurRadius: 20)],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('은혜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(8)),
                child: const Text('청년부 · 2셀', style: TextStyle(fontSize: 11, color: AC.muted)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text('“오늘도 주님 안에서 😊”', style: TextStyle(fontSize: 12.5, color: AC.muted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x14FFFFFF)), bottom: BorderSide(color: Color(0x14FFFFFF))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _Stat(n: '34', label: '출석'),
                _Stat(n: '12', label: '큐티'),
                _Stat(n: '5', label: '섬김'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final r in const [['🎨', '아바타 꾸미기'], ['🔔', '알림 설정'], ['🙏', '나의 기도제목']])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF)))),
              child: Row(
                children: [
                  Text(r[0], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r[1], style: const TextStyle(fontSize: 14, color: Colors.white))),
                  const Icon(Icons.chevron_right, color: AC.muted, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String n;
  final String label;
  const _Stat({required this.n, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(n, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AC.muted)),
      ],
    );
  }
}

/// 바텀시트 공통 셸 (그랩 핸들 + 글래스).
class _PanelShell extends StatelessWidget {
  final Widget child;
  const _PanelShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AC.glassFill,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
          ),
          padding: EdgeInsets.fromLTRB(18, 10, 18, 34 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
