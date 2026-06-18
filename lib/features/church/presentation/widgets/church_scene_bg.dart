import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
            Positioned(left: 0, top: 0, height: h * 0.7, width: w * 0.2, child: const _SideArch(left: true)),
            Positioned(right: 0, top: 0, height: h * 0.7, width: w * 0.2, child: const _SideArch(left: false)),
            if (godrays)
              Positioned(top: h * 0.11, left: 0, right: 0, height: h * 0.74, child: const GodRays()),
            Positioned(top: h * 0.065, left: w / 2 - 45, child: const StainedWindow()),
            Positioned(top: h * 0.20, left: w / 2 - 23, child: const CrossGlow()),
            Positioned(left: 0, right: 0, bottom: 0, height: h * 0.44, child: const FloorPlane()),
            const Positioned.fill(child: DustField()),
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

class StainedWindow extends StatelessWidget {
  const StainedWindow({super.key});
  static const double w = 90, h = 132;

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
          // 창 뒤 광원 글로우
          Positioned(
            left: -130,
            top: -80,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AC.glow(0.7).withOpacity(1.0), AC.light.withOpacity(0.0)],
                      stops: const [0, 0.55],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 스테인드글라스 (밝기 부스트)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              1.6, 0, 0, 0, 25,
              0, 1.6, 0, 0, 25,
              0, 0, 1.6, 0, 25,
              0, 0, 0, 1, 0,
            ]),
            child: ClipPath(
              clipper: _ArchClipper(),
              child: SizedBox(
                width: w,
                height: h,
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color.lerp(color, Colors.white, 0.65)!, color],
          stops: const [0, 0.7],
        ),
      ),
      foregroundDecoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.3),
          radius: 0.65,
          colors: [Colors.white.withOpacity(0.55), Colors.transparent],
        ),
      ),
    );
  }
}

class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final ah = s.height * 0.40;
    return Path()
      ..moveTo(0, s.height)
      ..lineTo(0, ah)
      ..quadraticBezierTo(s.width / 2, -s.height * 0.05, s.width, ah)
      ..lineTo(s.width, s.height)
      ..close();
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
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AC.stone,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
          Positioned(
            top: 0,
            child: Container(
              width: 7,
              height: 76,
              decoration: BoxDecoration(gradient: bar, borderRadius: BorderRadius.circular(4), boxShadow: glowShadows),
            ),
          ),
          Positioned(
            top: 20,
            child: Container(
              width: 42,
              height: 7,
              decoration: BoxDecoration(gradient: bar, borderRadius: BorderRadius.circular(4), boxShadow: glowShadows),
            ),
          ),
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
    const angles = [-40.0, -22.0, -6.0, 10.0, 26.0, 44.0];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final flick = 0.55 + 0.35 * _c.value;
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
                      opacity: (flick - a.abs() / 180).clamp(0.0, 1.0),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: 80,
                          height: 560,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AC.light.withOpacity(1.0), Colors.transparent],
                              stops: const [0, 0.72],
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
    const cols = 16;
    for (var i = 0; i <= cols; i++) {
      final xBottom = (i / cols) * (s.width * 2) - s.width * 0.5;
      paint.color = light.withOpacity(0.16);
      canvas.drawLine(Offset(xBottom, s.height), Offset(vpX, 0), paint);
    }
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

// ─── 예배당 전용 배경 ────────────────────────────────────────────────────────

class WorshipScene extends StatelessWidget {
  const WorshipScene({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          children: [
            // 배경 그라데이션 (남색/인디고)
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.55),
                    radius: 1.3,
                    colors: [
                      Color(0xFF3A4A8C),
                      Color(0xFF1A2260),
                      Color(0xFF0D1240),
                      Color(0xFF060818),
                    ],
                    stops: [0, 0.30, 0.60, 1],
                  ),
                ),
              ),
            ),
            // 무대 영역 (상단)
            Positioned(
              top: 0, left: 0, right: 0,
              height: h * 0.48,
              child: const _StagePlatform(),
            ),
            // 무대 스포트라이트들
            Positioned(
              top: 0, left: 0, right: 0,
              height: h * 0.75,
              child: const _StageSpotlights(),
            ),
            // 양쪽 커튼
            Positioned(left: 0, top: 0, width: w * 0.14, height: h * 0.62,
                child: const _Curtain(left: true)),
            Positioned(right: 0, top: 0, width: w * 0.14, height: h * 0.62,
                child: const _Curtain(left: false)),
            // 황금 십자가
            Positioned(
              top: h * 0.04,
              left: w / 2 - 18,
              child: const _GoldCross(),
            ),
            // 바닥 배경
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: h * 0.55,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xFF141A50), Color(0xFF0A0E30)],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
            ),
            // 바닥 그리드
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: h * 0.55,
              child: const _WarmFloor(),
            ),
            // 바닥 남색 글로우
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: h * 0.38,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: 0.9,
                      colors: [const Color(0xFF4466FF).withOpacity(0.30), Colors.transparent],
                      stops: const [0, 1],
                    ),
                  ),
                ),
              ),
            ),
            // 먼지 파티클 (따뜻한 색)
            const Positioned.fill(child: _WarmDust()),
            // 좌우 비네트만
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xBB1A0A02), Colors.transparent, Colors.transparent, const Color(0xBB1A0A02)],
                      stops: const [0, 0.18, 0.82, 1],
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

class _StagePlatform extends StatelessWidget {
  const _StagePlatform();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StagePainter());
  }
}

class _StagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    // 무대 플랫폼 상단
    final stagePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF1E2860), const Color(0xFF0D1440)],
      ).createShader(Rect.fromLTWH(0, s.height * 0.6, s.width, s.height * 0.4));
    final stagePath = Path()
      ..moveTo(-s.width * 0.1, s.height)
      ..lineTo(s.width * 1.1, s.height)
      ..lineTo(s.width * 0.92, s.height * 0.62)
      ..lineTo(s.width * 0.08, s.height * 0.62)
      ..close();
    canvas.drawPath(stagePath, stagePaint);

    // 무대 앞 테두리 빛 (은빛)
    final edgePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, const Color(0xFF8899FF), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, s.height * 0.62, s.width, 3))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(s.width * 0.08, s.height * 0.62),
      Offset(s.width * 0.92, s.height * 0.62),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _StageSpotlights extends StatefulWidget {
  const _StageSpotlights();

  @override
  State<_StageSpotlights> createState() => _StageSpotlightsState();
}

class _StageSpotlightsState extends State<_StageSpotlights>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _SpotlightPainter(_c.value),
        size: Size.infinite,
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final double t;
  _SpotlightPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final spots = [
      (x: s.width * 0.28, alpha: 0.45 + 0.12 * math.sin(t * math.pi)),
      (x: s.width * 0.50, alpha: 0.60 + 0.10 * math.cos(t * math.pi + 1)),
      (x: s.width * 0.72, alpha: 0.45 + 0.12 * math.sin(t * math.pi + 2)),
    ];
    for (final sp in spots) {
      final rect = Rect.fromLTWH(sp.x - s.width * 0.22, 0, s.width * 0.44, s.height * 0.85);
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.0,
          colors: [
            const Color(0xFFDDE8FF).withOpacity(sp.alpha),
            const Color(0xFF7799FF).withOpacity(sp.alpha * 0.4),
            Colors.transparent,
          ],
          stops: const [0, 0.4, 1],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter o) => o.t != t;
}

class _Curtain extends StatelessWidget {
  final bool left;
  const _Curtain({required this.left});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [Color(0xCC06082A), Color(0x880D1240), Colors.transparent],
          stops: const [0, 0.6, 1],
        ),
      ),
    );
  }
}

class _GoldCross extends StatefulWidget {
  const _GoldCross();

  @override
  State<_GoldCross> createState() => _GoldCrossState();
}

class _GoldCrossState extends State<_GoldCross> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const goldGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF0A0), Color(0xFFFFB24D)],
    );
    return SizedBox(
      width: 36, height: 72,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 글로우
            IgnorePointer(
              child: FadeTransition(
                opacity: Tween(begin: 0.4, end: 0.75).animate(_c),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFB24D).withOpacity(0.7),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 세로
            Positioned(
              top: 0,
              child: Container(
                width: 6, height: 60,
                decoration: BoxDecoration(
                  gradient: goldGrad,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFFFB24D), blurRadius: 10),
                    BoxShadow(color: Color(0xFFFFD580), blurRadius: 20),
                  ],
                ),
              ),
            ),
            // 가로
            Positioned(
              top: 16,
              child: Container(
                width: 34, height: 6,
                decoration: BoxDecoration(
                  gradient: goldGrad,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFFFB24D), blurRadius: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmFloor extends StatelessWidget {
  const _WarmFloor();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.white, Colors.transparent],
        stops: [0, 0.85],
      ).createShader(rect),
      child: CustomPaint(painter: _WarmFloorPainter()),
    );
  }
}

class _WarmFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final vpX = s.width / 2;
    final paint = Paint()..strokeWidth = 1;
    const cols = 14;
    for (var i = 0; i <= cols; i++) {
      final xBottom = (i / cols) * (s.width * 2) - s.width * 0.5;
      paint.color = const Color(0xFF6688FF).withOpacity(0.14);
      canvas.drawLine(Offset(xBottom, s.height), Offset(vpX, 0), paint);
    }
    const rows = 10;
    for (var j = 1; j <= rows; j++) {
      final t = j / rows;
      final y = s.height * (1 - t * t);
      paint.color = const Color(0xFF4466CC).withOpacity(0.12 * t);
      canvas.drawLine(Offset(0, y), Offset(s.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _WarmDust extends StatefulWidget {
  const _WarmDust();

  @override
  State<_WarmDust> createState() => _WarmDustState();
}

class _WarmDustState extends State<_WarmDust> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final r = math.Random(42);
    _motes = List.generate(22, (_) => _Mote(
      x: r.nextDouble(),
      y: 0.05 + r.nextDouble() * 0.6,
      size: 1 + r.nextDouble() * 2.2,
      phase: r.nextDouble() * math.pi * 2,
      speed: 0.5 + r.nextDouble() * 0.7,
      opacity: 0.12 + r.nextDouble() * 0.35,
    ));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _DustPainter(_c.value, _motes, const Color(0xFFAABBFF)),
          size: Size.infinite,
        ),
      ),
    );
  }
}
