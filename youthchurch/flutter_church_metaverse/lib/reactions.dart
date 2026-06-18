import 'package:flutter/material.dart';

/// 떠오르는 리액션 이모지 (탭/인사 시 생성 → 자동 소멸).
class ReactionItem {
  final int id;
  final String emoji;
  final double left; // % (0~100)
  final double bottom; // % (0~100)
  final double drift; // px
  ReactionItem(this.id, this.emoji, this.left, this.bottom, this.drift);
}

class FloatingReaction extends StatefulWidget {
  final String emoji;
  final double drift;
  final VoidCallback onEnd;
  const FloatingReaction({super.key, required this.emoji, required this.drift, required this.onEnd});

  @override
  State<FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<FloatingReaction> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onEnd();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final dy = -140 * Curves.easeOut.transform(t);
        final dx = widget.drift * t;
        final scale = t < 0.18 ? 0.5 + (t / 0.18) * 0.6 : 1.0;
        final op = t < 0.18 ? (t / 0.18) : (1 - ((t - 0.18) / 0.82));
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: op.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 24, shadows: [Shadow(color: Color(0x80000000), blurRadius: 6)])),
            ),
          ),
        );
      },
    );
  }
}
