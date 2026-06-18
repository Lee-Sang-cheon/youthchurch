import 'dart:ui';
import 'package:flame/components.dart';

class MapComponent extends Component {
  static const double tileSize = 64;
  static const int cols = 20;
  static const int rows = 22;

  static const double mapW = tileSize * cols; // 1280
  static const double mapH = tileSize * rows; // 1408

  @override
  void render(Canvas canvas) {
    _drawFloor(canvas);
    _drawWalls(canvas);
    _drawAltarArea(canvas);
    _drawCross(canvas);
    _drawAisle(canvas);
    _drawPews(canvas);
    _drawWindows(canvas);
    _drawEntrance(canvas);
  }

  // 나무 바닥
  void _drawFloor(Canvas canvas) {
    const light = Color(0xFFE8C99A);
    const dark = Color(0xFFD4B07A);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize),
          Paint()..color = (r + c) % 2 == 0 ? light : dark,
        );
      }
    }
  }

  // 벽
  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()..color = const Color(0xFF6B4F3A);
    final wallDark = Paint()..color = const Color(0xFF4A3526);

    // 상단 벽
    canvas.drawRect(Rect.fromLTWH(0, 0, mapW, tileSize), wallPaint);
    // 하단 벽
    canvas.drawRect(Rect.fromLTWH(0, mapH - tileSize, mapW, tileSize), wallPaint);
    // 좌측 벽
    canvas.drawRect(Rect.fromLTWH(0, 0, tileSize, mapH), wallPaint);
    // 우측 벽
    canvas.drawRect(Rect.fromLTWH(mapW - tileSize, 0, tileSize, mapH), wallPaint);

    // 벽 테두리 선
    canvas.drawRect(
      Rect.fromLTWH(tileSize - 8, tileSize - 8, mapW - tileSize * 2 + 16, mapH - tileSize * 2 + 16),
      Paint()
        ..color = wallDark.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
  }

  // 제단 영역 (상단)
  void _drawAltarArea(Canvas canvas) {
    // 제단 바닥 (밝은 색)
    canvas.drawRect(
      Rect.fromLTWH(tileSize, tileSize, mapW - tileSize * 2, tileSize * 4),
      Paint()..color = const Color(0xFFFFF3DC),
    );
    // 제단 구분선
    canvas.drawRect(
      Rect.fromLTWH(tileSize, tileSize * 5 - 8, mapW - tileSize * 2, 8),
      Paint()..color = const Color(0xFF8B6B47),
    );
    // 제단 테이블
    canvas.drawRect(
      Rect.fromLTWH(mapW / 2 - 120, tileSize * 3.2, 240, 60),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    // 제단 테이블 하이라이트
    canvas.drawRect(
      Rect.fromLTWH(mapW / 2 - 120, tileSize * 3.2, 240, 8),
      Paint()..color = const Color(0xFFAD7A55),
    );
  }

  // 십자가
  void _drawCross(Canvas canvas) {
    final crossPaint = Paint()..color = const Color(0xFFDAA520);
    final cx = mapW / 2;
    final cy = tileSize * 2.2;
    // 세로
    canvas.drawRect(Rect.fromLTWH(cx - 14, cy - 55, 28, 90), crossPaint);
    // 가로
    canvas.drawRect(Rect.fromLTWH(cx - 45, cy - 32, 90, 24), crossPaint);
    // 십자가 광채
    final glowPaint = Paint()
      ..color = const Color(0x44FFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy - 10), 50, glowPaint);
  }

  // 중앙 통로 (빨간 카펫)
  void _drawAisle(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(mapW / 2 - 48, tileSize * 5, 96, mapH - tileSize * 7),
      Paint()..color = const Color(0xFF8B0000),
    );
    // 카펫 테두리
    canvas.drawRect(
      Rect.fromLTWH(mapW / 2 - 48, tileSize * 5, 96, mapH - tileSize * 7),
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  // 의자 (pews)
  void _drawPews(Canvas canvas) {
    final pewPaint = Paint()..color = const Color(0xFF8B5E3C);
    final pewHighlight = Paint()..color = const Color(0xFFAD7A55);
    final pewShadow = Paint()..color = const Color(0xFF5C3D1E);

    // 의자 행: 6~18행, 2칸씩 건너뜀
    for (int row = 6; row <= 18; row += 2) {
      final y = row * tileSize + 8;

      // 좌측 의자 (2개 섹션)
      for (final startCol in [1.5, 4.5]) {
        final x = startCol * tileSize + 8;
        final w = tileSize * 2.5 - 16;
        canvas.drawRect(Rect.fromLTWH(x, y, w, tileSize - 20), pewPaint);
        canvas.drawRect(Rect.fromLTWH(x, y, w, 6), pewHighlight);
        canvas.drawRect(Rect.fromLTWH(x, y + tileSize - 26, w, 6), pewShadow);
      }

      // 우측 의자 (2개 섹션)
      for (final startCol in [11.0, 14.0]) {
        final x = startCol * tileSize + 8;
        final w = tileSize * 2.5 - 16;
        canvas.drawRect(Rect.fromLTWH(x, y, w, tileSize - 20), pewPaint);
        canvas.drawRect(Rect.fromLTWH(x, y, w, 6), pewHighlight);
        canvas.drawRect(Rect.fromLTWH(x, y + tileSize - 26, w, 6), pewShadow);
      }
    }
  }

  // 스테인드글라스 창문
  void _drawWindows(Canvas canvas) {
    final colors = [
      const Color(0x99E53935), // 빨강
      const Color(0x991E88E5), // 파랑
      const Color(0x99F9A825), // 노랑
      const Color(0x9943A047), // 초록
    ];

    // 좌측 벽 창문
    for (int i = 0; i < 4; i++) {
      final y = tileSize * (5.5 + i * 3);
      _drawWindow(canvas, 2, y, colors[i % colors.length]);
    }

    // 우측 벽 창문
    for (int i = 0; i < 4; i++) {
      final y = tileSize * (5.5 + i * 3);
      _drawWindow(canvas, mapW - tileSize * 2 - 8, y, colors[(i + 2) % colors.length]);
    }
  }

  void _drawWindow(Canvas canvas, double x, double y, Color color) {
    // 창틀
    canvas.drawRect(
      Rect.fromLTWH(x, y, 48, 80),
      Paint()..color = const Color(0xFF4A3526),
    );
    // 색유리
    canvas.drawRect(
      Rect.fromLTWH(x + 5, y + 5, 38, 70),
      Paint()..color = color,
    );
    // 창 십자 살
    canvas.drawRect(Rect.fromLTWH(x + 22, y + 5, 4, 70), Paint()..color = const Color(0xFF4A3526));
    canvas.drawRect(Rect.fromLTWH(x + 5, y + 38, 38, 4), Paint()..color = const Color(0xFF4A3526));
  }

  // 출입구
  void _drawEntrance(Canvas canvas) {
    // 문 (하단 중앙)
    canvas.drawRect(
      Rect.fromLTWH(mapW / 2 - 56, mapH - tileSize - 4, 112, tileSize + 4),
      Paint()..color = const Color(0xFF5C3D1E),
    );
    canvas.drawRect(
      Rect.fromLTWH(mapW / 2 - 48, mapH - tileSize, 96, tileSize),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    // 문 손잡이
    canvas.drawCircle(
      Offset(mapW / 2 + 20, mapH - tileSize * 0.5),
      5,
      Paint()..color = const Color(0xFFDAA520),
    );
  }
}
