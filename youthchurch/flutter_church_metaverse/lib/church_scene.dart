import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

/// 예배당(성소) 배경 전체: 하늘 그라데이션, 스테인드글라스 창, 십자가,
/// 빛기둥(godray), 원근 바닥, 떠다니는 먼지, 비네트.
class ChurchScene extends StatelessWidget {
  final bool godrays;
  const ChurchScene({super.key, this.godrays = true});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          children: [
            // 하늘
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.9),
                    radius: 1.1,
                    colors: [
                      AC.mix(AC.light, AC.bgMid, 0.78),
                      AC.bgMid,
                      const Color(0xFF0C0820),
                      const Color(0xFF070512),
                    ],
                    stops: const [0, 0.34, 0.64, 1],
                  ),
                ),
              ),
            ),
            // 측면 아치(어두운 프레이밍)
            Positioned(left: 0, top: 0, height: h * 0.7, width: w * 0.2, child: const _SideArch(left: true)),
            Positioned(right: 0, top: 0, height: h * 0.7, width: w * 0.2, child: const _SideArch(left: false)),

            // 빛기둥
            if (godrays)
              Positioned(top: h * 0.11, left: 0, right: 0, height: h * 0.74, child: const GodRays()),

            // 스테인드글라스 창
            Positioned(top: h * 0.065, left: w / 2 - 74, child: const StainedWindow()),

            // 십자가
            Positioned(top: h * 0.34, left: w / 2 - 23, child: const CrossGlow()),

            // 바닥
            Positioned(left: 0, right: 0, bottom: 0, height: h * 0.44, child: const FloorPlane()),

            // 먼지
            const Positioned.fill(child: DustField()),

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
      },
    );
  }
}

class _SideArch extends StatelessWidget {
  final bool left;
  const _SideArch({required this.left});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [Color(0xEB05030C), Colors.transparent],
        ),
        borderRadius: BorderRadius.only(
          topRight: left ? const Radius.elliptical(80, 50) : Radius.zero,
          topLeft: left ? Radius.zero : const Radius.elliptical(80, 50),
        ),
      ),
    );
  }
}

// ───────────────────── 스테인드글라스 창 ─────────────────────
class StainedWindow extends StatelessWidget {
  const StainedWindow({super.key});

  static const double w = 148, h = 218;

  @override
  Widget build(BuildContext context) {
    const panes = [
      [AC.glass1, AC.glass2],
      [AC.glass3, AC.glass1],
      [AC.glass2, AC.glass3],
    ];
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 뒤 글로우
          Positioned(
            left: -96,
            top: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AC.glow(0.7).withOpacity(0.85), AC.light.withOpacity(0.0)],
                      stops: const [0, 0.6],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 유리 패널
          ClipPath(
            clipper: _ArchClipper(),
            child: Container(
              color: AC.mullion,
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  for (var r = 0; r < 3; r++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            for (var col = 0; col < 2; col++) ...[
                              if (col == 1) const SizedBox(width: 5),
                              Expanded(child: _Pane(color: panes[r][col])),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 돌 프레임
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ArchBorderPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final Color color;
  const _Pane({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [
            Color.lerp(color, Colors.white, 0.55)!,
            color,
          ],
          stops: const [0, 0.7],
        ),
      ),
    );
  }
}

class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final ah = s.height * 0.40;
    final p = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, ah)
      ..quadraticBezierTo(s.width / 2, -s.height * 0.05, s.width, ah)
      ..lineTo(s.width, s.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArchBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final ah = s.height * 0.40;
    final path = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, ah)
      ..quadraticBezierTo(s.width / 2, -s.height * 0.05, s.width, ah)
      ..lineTo(s.width, s.height);
    final stone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AC.stone;
    canvas.drawPath(path, stone);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────── 십자가 ─────────────────────
class CrossGlow extends StatefulWidget {
  const CrossGlow({super.key});
  @override
  State<CrossGlow> createState() => _CrossGlowState();
}

class _CrossGlowState extends State<CrossGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFFFF8E8), AC.glow(0.7)],
    );
    final glowShadows = [
      BoxShadow(color: AC.glow(0.8), blurRadius: 14),
      BoxShadow(color: AC.light.withOpacity(0.55), blurRadius: 30),
    ];
    return SizedBox(
      width: 46,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 후광
          Positioned(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: Tween(begin: 0.5, end: 0.85).animate(_c),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AC.glow(0.8).withOpacity(0.65), Colors.transparent],
                        stops: const [0, 0.58],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 세로 막대
          Positioned(
            top: 0,
            child: Container(
              width: 7,
              height: 76,
              decoration: BoxDecoration(gradient: bar, borderRadius: BorderRadius.circular(4), boxShadow: glowShadows),
            ),
          ),
          // 가로 막대
          Positioned(
            top: 20,
            child: Container(
              width: 42,
              height: 7,
              decoration: BoxDecoration(gradient: bar, borderRadius: BorderRadius.circular(4), boxShadow: glowShadows),
            ),
          ),
          // 코어
          Positioned(
            top: 14,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFFDF5),
                boxShadow: [
                  const BoxShadow(color: Colors.white, blurRadius: 22),
                  BoxShadow(color: AC.glow(0.7), blurRadius: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── 빛기둥(godray) ─────────────────────
class GodRays extends StatefulWidget {
  const GodRays({super.key});
  @override
  State<GodRays> createState() => _GodRaysState();
}

class _GodRaysState extends State<GodRays> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const angles = [-34.0, -18.0, -4.0, 12.0, 28.0];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final flick = 0.42 + 0.28 * _c.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              for (final a in angles)
                Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.rotationZ(a * math.pi / 180),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: (flick - a.abs() / 200).clamp(0.0, 1.0),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                        child: Container(
                          width: 60,
                          height: 520,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AC.light.withOpacity(0.6), Colors.transparent],
                              stops: const [0, 0.78],
                            ),
                          ),
                        ),
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
}

// ───────────────────── 원근 바닥 ─────────────────────
class FloorPlane extends StatelessWidget {
  const FloorPlane({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.white, Colors.transparent],
              stops: [0.0, 0.82],
            ).createShader(rect),
            child: CustomPaint(painter: _FloorPainter(AC.light)),
          ),
        ),
        // 바닥 빛 웅덩이
        Positioned(
          left: 0,
          right: 0,
          bottom: -20,
          height: 220,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 0.9,
                  colors: [AC.light.withOpacity(0.4), Colors.transparent],
                  stops: const [0, 0.64],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloorPainter extends CustomPainter {
  final Color light;
  _FloorPainter(this.light);

  @override
  void paint(Canvas canvas, Size s) {
    final vpX = s.width / 2;
    final paint = Paint()..strokeWidth = 1;
    // 수렴하는 세로선
    const cols = 16;
    for (var i = 0; i <= cols; i++) {
      final xBottom = (i / cols) * (s.width * 2) - s.width * 0.5;
      paint.color = light.withOpacity(0.16);
      canvas.drawLine(Offset(xBottom, s.height), Offset(vpX, 0), paint);
    }
    // 지평선으로 갈수록 촘촘한 가로선
    const rows = 10;
    for (var j = 1; j <= rows; j++) {
      final t = j / rows;
      final y = s.height * (1 - t * t);
      paint.color = light.withOpacity(0.14 * t);
      canvas.drawLine(Offset(0, y), Offset(s.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────── 떠다니는 먼지 ─────────────────────
class DustField extends StatefulWidget {
  const DustField({super.key});
  @override
  State<DustField> createState() => _DustFieldState();
}

class _DustFieldState extends State<DustField> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _motes = List.generate(26, (_) {
      return _Mote(
        x: r.nextDouble(),
        y: 0.08 + r.nextDouble() * 0.64,
        size: 1 + r.nextDouble() * 2.6,
        phase: r.nextDouble() * math.pi * 2,
        speed: 0.6 + r.nextDouble() * 0.8,
        opacity: 0.15 + r.nextDouble() * 0.4,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _DustPainter(_c.value, _motes, AC.glow(0.6)),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Mote {
  final double x, y, size, phase, speed, opacity;
  _Mote({required this.x, required this.y, required this.size, required this.phase, required this.speed, required this.opacity});
}

class _DustPainter extends CustomPainter {
  final double t;
  final List<_Mote> motes;
  final Color color;
  _DustPainter(this.t, this.motes, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final m in motes) {
      final a = t * math.pi * 2 * m.speed + m.phase;
      final dx = math.cos(a) * 10;
      final dy = math.sin(a) * 22;
      paint.color = color.withOpacity(m.opacity);
      canvas.drawCircle(Offset(m.x * s.width + dx, m.y * s.height + dy), m.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) => oldDelegate.t != t;
}
