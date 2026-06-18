import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'glass.dart';
import 'reactions.dart';

/// 예배 라이브 룸: 무대 조명, 십자가, 밴드 실루엣, 가사, 리액션.
class WorshipScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WorshipScreen({super.key, required this.onBack});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  static const _lines = ['주 은혜임을 나 알아', '이 모든 순간이 선물인 걸', '내 삶의 이유 되신 주'];
  int _idx = 0;
  Timer? _timer;
  final List<ReactionItem> _reactions = [];
  int _rid = 0;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      setState(() => _idx = (_idx + 1) % _lines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _react(String emoji) {
    final id = ++_rid;
    setState(() => _reactions.add(ReactionItem(id, emoji, 30 + _rand.nextDouble() * 40, 22, (_rand.nextDouble() - 0.5) * 70)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        const Positioned.fill(child: _WorshipSceneBg()),
        // 리액션
        ..._reactions.map((r) => Positioned(
              left: r.left / 100 * size.width,
              bottom: r.bottom / 100 * size.height,
              child: FloatingReaction(
                emoji: r.emoji,
                drift: r.drift,
                onEnd: () => setState(() => _reactions.removeWhere((x) => x.id == r.id)),
              ),
            )),
        // 상단 바
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Glass(
                    radius: 999,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.chevron_left, color: Colors.white, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Glass(
                    radius: 999,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AC.live,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [BoxShadow(color: AC.live.withOpacity(0.5), blurRadius: 10)],
                          ),
                          child: const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        const Text('주일 청년예배', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Glass(
                  radius: 999,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  child: const Text('👁 128', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        // 가사
        Positioned(
          left: 20,
          right: 20,
          bottom: 180,
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _lines[_idx],
                  key: ValueKey(_idx),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.4,
                    shadows: [
                      Shadow(color: AC.light.withOpacity(0.6), blurRadius: 16),
                      const Shadow(color: Color(0x99000000), blurRadius: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(_lines[(_idx + 1) % _lines.length],
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AC.muted)),
            ],
          ),
        ),
        // 리액션 바
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final e in ['🙏', '❤️', '🔥', '✨', '🕊️'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _ReactButton(emoji: e, onTap: () => _react(e)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;
  const _ReactButton({required this.emoji, required this.onTap});

  @override
  State<_ReactButton> createState() => _ReactButtonState();
}

class _ReactButtonState extends State<_ReactButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x80161326),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
                boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6))],
              ),
              child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────── 예배 무대 배경 ─────────────────────
class _WorshipSceneBg extends StatefulWidget {
  const _WorshipSceneBg();
  @override
  State<_WorshipSceneBg> createState() => _WorshipSceneBgState();
}

class _WorshipSceneBgState extends State<_WorshipSceneBg> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      return Stack(
        children: [
          // 하늘
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.0,
                  colors: const [Color(0xFF2A1330), Color(0xFF160A22), Color(0xFF08040F)],
                  stops: const [0, 0.46, 1],
                ),
              ),
            ),
          ),
          // 스포트라이트
          for (final spot in [
            [w * 0.18, -16.0, 0.0],
            [w * 0.5 - 80, 2.0, 1.0],
            [w * 0.82, 16.0, 2.0],
          ])
            Positioned(
              top: -h * 0.06,
              left: spot[0],
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Opacity(
                  opacity: 0.4 + 0.4 * ((math.sin((_c.value * 2 * math.pi) + spot[2]) + 1) / 2),
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.rotationZ((spot[1] as double) * math.pi / 180),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 160,
                        height: h * 1.1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AC.light.withOpacity(0.55), Colors.transparent],
                            stops: const [0, 0.7],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 무대 헤이즈
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: h * 0.5,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AC.light.withOpacity(0.22), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 밴드 실루엣
          for (final bm in [
            [w * 0.24, 82.0],
            [w * 0.5 - 20, 96.0],
            [w * 0.76 - 40, 80.0],
          ])
            Positioned(
              left: bm[0],
              bottom: h * 0.34 * 0.22,
              child: _BandMember(height: bm[1]),
            ),
          // 무대 가장자리
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: h * 0.34 * 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x668B0510), Color(0xFF05030C)],
                ),
                border: Border(top: BorderSide(color: AC.light.withOpacity(0.3))),
              ),
            ),
          ),
          // 십자가
          Positioned(top: h * 0.32, left: w / 2 - 23, child: const CrossGlowSmall()),
          // 비네트
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.16),
                    radius: 1.0,
                    colors: [Colors.transparent, const Color(0xF0040208)],
                    stops: const [0.38, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _BandMember extends StatelessWidget {
  final double height;
  const _BandMember({required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1230), Color(0xFF0C0820)]),
          ),
        ),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1230), Color(0xFF0C0820)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            boxShadow: [BoxShadow(color: AC.light.withOpacity(0.35), blurRadius: 24)],
          ),
        ),
      ],
    );
  }
}

/// 예배실용 십자가 (church_scene의 것과 동일 디자인, 의존성 분리를 위해 재사용).
class CrossGlowSmall extends StatelessWidget {
  const CrossGlowSmall({super.key});

  @override
  Widget build(BuildContext context) {
    final bar = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFF8E8), AC.glow(0.7)]);
    final glows = [BoxShadow(color: AC.glow(0.8), blurRadius: 14), BoxShadow(color: AC.light.withOpacity(0.55), blurRadius: 30)];
    return SizedBox(
      width: 46,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AC.glow(0.8).withOpacity(0.6), Colors.transparent], stops: const [0, 0.58]),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, child: Container(width: 7, height: 76, decoration: BoxDecoration(gradient: bar, borderRadius: BorderRadius.circular(4), boxShadow: glows))),
          Positioned(top: 20, child: Container(width: 42, height: 7, decoration: BoxDecoration(gradient: bar, borderRadius: BorderRadius.circular(4), boxShadow: glows))),
          Positioned(
            top: 14,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFFDF5), boxShadow: [const BoxShadow(color: Colors.white, blurRadius: 22), BoxShadow(color: AC.glow(0.7), blurRadius: 44)]),
            ),
          ),
        ],
      ),
    );
  }
}
