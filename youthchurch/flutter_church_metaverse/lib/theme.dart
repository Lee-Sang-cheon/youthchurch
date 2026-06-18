import 'package:flutter/material.dart';

/// 앱 전역 색상 토큰 (HTML 프로토타입의 CSS 변수와 1:1 대응).
class AC {
  AC._();

  static const Color light = Color(0xFFFFB24D); // 신성한 조명색 (--light)
  static const Color glass1 = Color(0xFF7C5CFF); // 스테인드글라스 (--glass1)
  static const Color glass2 = Color(0xFF3BD6C6); // (--glass2)
  static const Color glass3 = Color(0xFFFF7EB6); // (--glass3)

  static const Color ink = Color(0xFFF4F1FF);
  static const Color muted = Color(0x9EECE9FF); // ~62% 흰빛
  static const Color live = Color(0xFFFF4D6A);
  static const Color online = Color(0xFF4BE38A);

  static const Color bgTop = Color(0xFF15131F);
  static const Color bgMid = Color(0xFF160F2A);
  static const Color bgBot = Color(0xFF05040A);

  static const Color glassFill = Color(0x85161326); // rgba(22,19,38,.52)
  static const Color stone = Color(0xFF1C1530);
  static const Color mullion = Color(0xFF0A0814);

  /// CSS의 color-mix(... in oklab) 근사: a→b 선형 보간.
  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// 빛 색을 흰색과 섞은 밝은 글로우 색.
  static Color glow([double whiteAmt = 0.4]) => mix(light, Colors.white, whiteAmt);
}

/// 부드러운 그림자/글로우 헬퍼.
List<BoxShadow> glowShadow(Color c, {double blur = 18, double spread = 0}) => [
      BoxShadow(color: c, blurRadius: blur, spreadRadius: spread),
    ];
