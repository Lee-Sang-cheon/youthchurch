import 'package:flutter/material.dart';

class MafiaTimerRing extends StatelessWidget {
  final int seconds;
  final int total;
  const MafiaTimerRing({super.key, required this.seconds, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (seconds / total).clamp(0.0, 1.0) : 0.0;
    final isWarning = seconds <= 10 && seconds > 0;
    final color = isWarning ? Colors.orange : const Color(0xFFFF4D6A);

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text('$seconds',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? Colors.orange : Colors.white)),
        ],
      ),
    );
  }
}
