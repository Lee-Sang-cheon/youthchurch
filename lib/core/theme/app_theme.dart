import 'package:flutter/material.dart';

class AC {
  AC._();

  static const Color light = Color(0xFFFFB24D);
  static const Color glass1 = Color(0xFF7C5CFF);
  static const Color glass2 = Color(0xFF3BD6C6);
  static const Color glass3 = Color(0xFFFF7EB6);

  static const Color ink = Color(0xFFF4F1FF);
  static const Color muted = Color(0x9EECE9FF);
  static const Color live = Color(0xFFFF4D6A);
  static const Color online = Color(0xFF4BE38A);

  static const Color bgTop = Color(0xFF15131F);
  static const Color bgMid = Color(0xFF160F2A);
  static const Color bgBot = Color(0xFF05040A);

  static const Color glassFill = Color(0x85161326);
  static const Color stone = Color(0xFF1C1530);
  static const Color mullion = Color(0xFF0A0814);

  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
  static Color glow([double whiteAmt = 0.4]) => mix(light, Colors.white, whiteAmt);
}

List<BoxShadow> glowShadow(Color c, {double blur = 18, double spread = 0}) => [
      BoxShadow(color: c, blurRadius: blur, spreadRadius: spread),
    ];
