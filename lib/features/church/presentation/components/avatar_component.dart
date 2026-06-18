import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class AvatarComponent extends PositionComponent {
  static const double _speed = 180;
  static const double _size = 36;

  Vector2? _target;

  AvatarComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(_size),
          anchor: Anchor.center,
        );

  void moveTo(Vector2 worldPosition) {
    _target = worldPosition.clone();
  }

  @override
  void update(double dt) {
    if (_target == null) return;
    final diff = _target! - position;
    if (diff.length <= _speed * dt) {
      position = _target!;
      _target = null;
    } else {
      position += diff.normalized() * _speed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // 몸통 (원)
    canvas.drawCircle(
      Offset(_size / 2, _size / 2 + 6),
      _size / 2.8,
      Paint()..color = const Color(0xFF5B9BD5),
    );
    // 머리 (원)
    canvas.drawCircle(
      Offset(_size / 2, _size / 2 - 8),
      _size / 4.5,
      Paint()..color = const Color(0xFFFFD8A8),
    );
    // 테두리
    canvas.drawCircle(
      Offset(_size / 2, _size / 2 - 8),
      _size / 4.5,
      Paint()
        ..color = const Color(0xFFB07040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }
}
