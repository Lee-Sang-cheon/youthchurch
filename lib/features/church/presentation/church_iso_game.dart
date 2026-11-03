import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// ─── 다른 유저 데이터 ────────────────────────────────────────
class IsoUser {
  final String uid;
  final String name;
  final Color color;
  double col;
  double row;

  IsoUser({
    required this.uid,
    required this.name,
    required this.color,
    required this.col,
    required this.row,
  });
}

// ─── 이소메트릭 게임 ─────────────────────────────────────────
class ChurchIsoGame extends FlameGame with TapCallbacks {
  static const double tileW = 80.0;
  static const double tileH = 40.0;
  static const int gridCols = 22;
  static const int gridRows = 22;

  double playerCol;
  double playerRow;
  double _targetCol;
  double _targetRow;

  final String playerName;
  final Color playerColor;
  final void Function(double col, double row)? onMove;

  List<IsoUser> otherUsers = [];

  ChurchIsoGame({
    double startCol = 11.0,
    double startRow = 11.0,
    this.playerName = '나',
    this.playerColor = const Color(0xFFFFB44D),
    this.onMove,
  })  : playerCol = startCol,
        playerRow = startRow,
        _targetCol = startCol,
        _targetRow = startRow;

  @override
  Color backgroundColor() => const Color(0xFF080512);

  // 카메라 오프셋 (플레이어가 화면 중앙에 오도록)
  Vector2 get _cameraOffset => Vector2(
        size.x / 2 - (playerCol - playerRow) * tileW / 2,
        size.y / 2 - (playerCol + playerRow) * tileH / 2 + size.y * 0.04,
      );

  // 그리드 → 화면 좌표
  static Vector2 isoToScreen(double col, double row) {
    return Vector2(
      (col - row) * tileW / 2,
      (col + row) * tileH / 2,
    );
  }

  @override
  Future<void> onLoad() async {
    add(_IsoRenderer());
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final offset = _cameraOffset;
    final wx = event.canvasPosition.x - offset.x;
    final wy = event.canvasPosition.y - offset.y;

    final col = (wx / tileW + wy / tileH).roundToDouble().clamp(1.0, gridCols - 2.0);
    final row = (wy / tileH - wx / tileW).roundToDouble().clamp(1.0, gridRows - 2.0);

    _targetCol = col;
    _targetRow = row;
    onMove?.call(col, row);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    const speed = 8.0;
    final dx = _targetCol - playerCol;
    final dy = _targetRow - playerRow;
    if (dx.abs() > 0.01 || dy.abs() > 0.01) {
      playerCol += dx * speed * dt;
      playerRow += dy * speed * dt;
    }
  }

  // ─── 바닥 타일 렌더링 ────────────────────────────────────
  void _renderFloor(Canvas canvas) {
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        final pos = isoToScreen(c.toDouble(), r.toDouble());
        _drawTile(canvas, pos.x, pos.y, c, r);
      }
    }
  }

  void _drawTile(Canvas canvas, double x, double y, int col, int row) {
    final isWall = col == 0 || col == gridCols - 1 || row == 0 || row == gridRows - 1;
    final checker = (col + row) % 2 == 0;

    final path = Path()
      ..moveTo(x, y - tileH / 2)
      ..lineTo(x + tileW / 2, y)
      ..lineTo(x, y + tileH / 2)
      ..lineTo(x - tileW / 2, y)
      ..close();

    final Color fill = isWall
        ? const Color(0xFF0D0A20)
        : (checker ? const Color(0xFF1C1842) : const Color(0xFF231F52));

    canvas.drawPath(path, Paint()..color = fill);

    // 테두리
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // 상단 하이라이트 (입체감)
    final highlight = Path()
      ..moveTo(x, y - tileH / 2)
      ..lineTo(x + tileW / 2, y)
      ..moveTo(x, y - tileH / 2)
      ..lineTo(x - tileW / 2, y);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withOpacity(isWall ? 0.04 : 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
  }

  // ─── 캐릭터 렌더링 (깊이 정렬) ───────────────────────────
  void _renderCharacters(Canvas canvas) {
    final entities = <(double depth, void Function(Canvas))>[];

    for (final u in otherUsers) {
      final snapshot = u;
      entities.add((
        snapshot.col + snapshot.row,
        (c) => _drawCharacter(c, snapshot.col, snapshot.row, snapshot.name, snapshot.color, false),
      ));
    }
    entities.add((
      playerCol + playerRow,
      (c) => _drawCharacter(c, playerCol, playerRow, playerName, playerColor, true),
    ));

    entities.sort((a, b) => a.$1.compareTo(b.$1));
    for (final e in entities) {
      e.$2(canvas);
    }
  }

  void _drawCharacter(Canvas canvas, double col, double row, String name, Color color, bool isSelf) {
    final pos = isoToScreen(col, row);
    final x = pos.x;
    final y = pos.y;
    final light = Color.lerp(color, Colors.white, 0.45)!;
    final dark = Color.lerp(color, Colors.black, 0.3)!;

    // 바닥 그림자
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 2), width: 34, height: 14),
      Paint()..color = Colors.black.withOpacity(0.4),
    );

    // 다리
    for (final lx in [x - 5.5, x + 2.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(lx, y - 17, 6.5, 17), const Radius.circular(3)),
        Paint()..color = dark,
      );
    }

    // 몸통
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 31), width: 24, height: 26),
        const Radius.circular(9),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, color],
        ).createShader(Rect.fromCenter(center: Offset(x, y - 31), width: 24, height: 26)),
    );

    // 팔 (좌우)
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + side * 15, y - 31), width: 7, height: 18),
          const Radius.circular(3),
        ),
        Paint()..color = light,
      );
    }

    // 머리
    canvas.drawCircle(
      Offset(x, y - 49),
      13,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [light, color],
        ).createShader(Rect.fromCenter(center: Offset(x, y - 49), width: 26, height: 26)),
    );

    // 눈
    for (final ex in [x - 4.5, x + 4.5]) {
      canvas.drawCircle(Offset(ex, y - 50), 2.8, Paint()..color = Colors.white.withOpacity(0.9));
      canvas.drawCircle(Offset(ex, y - 50), 1.3, Paint()..color = const Color(0xFF1A1030));
    }

    // 내 캐릭터 골든 링
    if (isSelf) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 3), width: 46, height: 18),
        Paint()
          ..color = const Color(0xFFFFCE7A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }

    // 이름 태그
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: isSelf ? const Color(0xFF3A2406) : Colors.white,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagW = tp.width + 16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 68), width: tagW, height: 18),
        const Radius.circular(10),
      ),
      Paint()..color = isSelf ? const Color(0xFFFFCE7A) : const Color(0xCC0E0B1A),
    );
    tp.paint(canvas, Offset(x - tp.width / 2, y - 68 - tp.height / 2));
  }
}

// ─── Flame 렌더러 컴포넌트 ────────────────────────────────────
class _IsoRenderer extends Component with HasGameRef<ChurchIsoGame> {
  @override
  void render(Canvas canvas) {
    final g = gameRef;
    final offset = g._cameraOffset;
    canvas.save();
    canvas.translate(offset.x, offset.y);
    g._renderFloor(canvas);
    g._renderCharacters(canvas);
    canvas.restore();
  }
}
