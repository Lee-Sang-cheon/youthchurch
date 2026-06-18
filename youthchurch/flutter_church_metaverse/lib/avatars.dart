import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';
import 'glass.dart';

enum AvatarStyle { blob, figure, orb }

/// 둥실 떠다니는 유저 아바타 (머리 + 몸통 + 글로우 + 발 밑 빛 웅덩이 + 이름표).
class AvatarFigure extends StatefulWidget {
  final AvatarUser user;
  final AvatarStyle style;
  final bool selected;
  final VoidCallback? onTap;
  final int seed;

  const AvatarFigure({
    super.key,
    required this.user,
    this.style = AvatarStyle.blob,
    this.selected = false,
    this.onTap,
    this.seed = 0,
  });

  @override
  State<AvatarFigure> createState() => _AvatarFigureState();
}

class _AvatarFigureState extends State<AvatarFigure> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _c.value = (widget.seed * 0.21) % 1.0; // idle 위상 분산
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: u.scale,
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final dy = math.sin(_c.value * math.pi * 2) * 4;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NameTag(u: u, selected: widget.selected),
              const SizedBox(height: 5),
              AvatarBody(color: u.color, color2: u.color2, style: widget.style, highlight: widget.selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  final AvatarUser u;
  final bool selected;
  const _NameTag({required this.u, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? u.color : const Color(0x990E0B1A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(0.14)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (u.live) ...[
            const PulseDot(color: AC.live, size: 5),
            const SizedBox(width: 4),
          ],
          Text(
            u.name,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF1A1030) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 머리/몸통/글로우/발광 풀 — 세 가지 스타일 지원.
class AvatarBody extends StatelessWidget {
  final Color color;
  final Color color2;
  final AvatarStyle style;
  final bool highlight;
  final bool self;

  const AvatarBody({
    super.key,
    required this.color,
    required this.color2,
    this.style = AvatarStyle.blob,
    this.highlight = false,
    this.self = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 글로우
          Positioned(
            bottom: 8,
            child: ImageFilteredGlow(color: color, size: style == AvatarStyle.orb ? 46 : 54, strong: highlight),
          ),
          // 발 밑 빛 웅덩이
          Positioned(
            bottom: -2,
            child: Container(
              width: 42,
              height: 13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.6), Colors.transparent],
                  stops: const [0, 0.68],
                ),
              ),
            ),
          ),
          if (self)
            Positioned(
              bottom: -4,
              child: const _SelfRing(),
            ),
          ..._buildBody(),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    final headGrad = RadialGradient(
      center: const Alignment(-0.3, -0.45),
      colors: [color2, color],
    );
    if (style == AvatarStyle.orb) {
      return [
        Positioned(
          bottom: 14,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.32, -0.4),
                colors: [Colors.white, color2, color],
                stops: const [0, 0.3, 0.78],
              ),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.7), blurRadius: 20),
                const BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
      ];
    }
    final headSize = style == AvatarStyle.figure ? 17.0 : 20.0;
    final torsoW = style == AvatarStyle.figure ? 22.0 : 30.0;
    final torsoH = style == AvatarStyle.figure ? 34.0 : 32.0;
    return [
      // 몸통
      Positioned(
        bottom: 8,
        child: Container(
          width: torsoW,
          height: torsoH,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color2, color]),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.elliptical(20, 26),
              topRight: Radius.elliptical(20, 26),
              bottomLeft: Radius.elliptical(16, 12),
              bottomRight: Radius.elliptical(16, 12),
            ),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
        ),
      ),
      // 머리
      Positioned(
        bottom: 8 + torsoH - 6,
        child: Container(
          width: headSize,
          height: headSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: headGrad,
            boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
        ),
      ),
    ];
  }
}

class ImageFilteredGlow extends StatefulWidget {
  final Color color;
  final double size;
  final bool strong;
  const ImageFilteredGlow({super.key, required this.color, this.size = 54, this.strong = false});

  @override
  State<ImageFilteredGlow> createState() => _ImageFilteredGlowState();
}

class _ImageFilteredGlowState extends State<ImageFilteredGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: widget.strong ? 0.9 : 0.7, end: 1.0).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [widget.color.withOpacity(0.6), Colors.transparent],
            stops: const [0, 0.64],
          ),
        ),
      ),
    );
  }
}

class _SelfRing extends StatefulWidget {
  const _SelfRing();
  @override
  State<_SelfRing> createState() => _SelfRingState();
}

class _SelfRingState extends State<_SelfRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(1.0, 0.42),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xE6FFDD96), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFFFFC86E).withOpacity(0.7), blurRadius: 14)],
          ),
        ),
      ),
    );
  }
}

/// 내 아바타.
class SelfAvatar extends StatefulWidget {
  final AvatarStyle style;
  const SelfAvatar({super.key, this.style = AvatarStyle.blob});

  @override
  State<SelfAvatar> createState() => _SelfAvatarState();
}

class _SelfAvatarState extends State<SelfAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, math.sin(_c.value * math.pi * 2) * 4), child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF5DC), Color(0xFFFFCE7A)],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white),
            ),
            child: const Text('나', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF3A2406))),
          ),
          const SizedBox(height: 5),
          AvatarBody(
            color: const Color(0xFFFFB44D),
            color2: const Color(0xFFFFE9B8),
            style: widget.style,
            self: true,
          ),
        ],
      ),
    );
  }
}

// ───────────────────── 룸 포털 ─────────────────────
class RoomPortal extends StatefulWidget {
  final String label;
  final String sub;
  final Color hue;
  final bool live;
  final VoidCallback onTap;
  const RoomPortal({super.key, required this.label, required this.sub, required this.hue, required this.onTap, this.live = false});

  @override
  State<RoomPortal> createState() => _RoomPortalState();
}

class _RoomPortalState extends State<RoomPortal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _down ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final glow = widget.live ? (0.5 + 0.3 * _c.value) : 0.5;
                return Container(
                  width: 58,
                  height: 74,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(29, 44),
                      topRight: Radius.elliptical(29, 44),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AC.mix(widget.hue, const Color(0x80140C24), 0.7), const Color(0xB30C0918)],
                    ),
                    border: Border.all(color: AC.mix(widget.hue, Colors.white, 0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: widget.hue.withOpacity(glow), blurRadius: widget.live ? 34 : 22)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: -22,
                        height: 66,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: RadialGradient(
                              center: Alignment.bottomCenter,
                              colors: [AC.mix(widget.hue, Colors.white, 0.4), Colors.transparent],
                              stops: const [0, 0.62],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.live) ...[
                const PulseDot(color: AC.live, size: 5),
                const SizedBox(width: 4),
              ],
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(color: Color(0xB3000000), blurRadius: 6)])),
            ],
          ),
          const SizedBox(height: 1),
          Text(widget.sub,
              style: const TextStyle(
                  fontSize: 9.5, color: AC.muted, shadows: [Shadow(color: Color(0xB3000000), blurRadius: 4)])),
        ],
      ),
    );
  }
}

// ───────────────────── 프로필 시트 ─────────────────────
void showProfileSheet(BuildContext context, AvatarUser u, void Function(AvatarUser, String) onGreet) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66040208),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(center: const Alignment(-0.3, -0.45), colors: [u.color2, u.color]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(u.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          if (u.live) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(color: AC.live, borderRadius: BorderRadius.circular(5)),
                              child: const Text('LIVE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(u.role, style: const TextStyle(fontSize: 12, color: AC.muted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                    child: const Icon(Icons.close, size: 15, color: AC.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('“${u.status}”', style: const TextStyle(fontSize: 13.5, color: Color(0xFFE9E4FF), height: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onGreet(u, '👋');
                    },
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                        ),
                        boxShadow: [BoxShadow(color: AC.light.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: const Text('👋  인사하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1030))),
                    ),
                  ),
                ),
                for (final e in ['🙏', '✨', '❤️']) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onGreet(u, e);
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: const Color(0x14FFFFFF),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 19)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
