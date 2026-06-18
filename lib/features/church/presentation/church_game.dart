import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'components/avatar_component.dart';
import 'components/map_component.dart';

class ChurchGame extends FlameGame with TapCallbacks {
  late AvatarComponent _avatar;

  static const double mapWidth = MapComponent.tileSize * MapComponent.cols;
  static const double mapHeight = MapComponent.tileSize * MapComponent.rows;

  @override
  Future<void> onLoad() async {
    final world = World();
    add(world);
    camera.world = world;

    world.add(MapComponent());

    // 아바타 시작 위치: 입구 근처 (하단 중앙)
    _avatar = AvatarComponent(
      position: Vector2(mapWidth / 2, mapHeight - MapComponent.tileSize * 3),
    );
    world.add(_avatar);

    camera.follow(_avatar);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 화면 좌표 → 월드 좌표 변환
    final worldPos = camera.globalToLocal(event.canvasPosition);
    _avatar.moveTo(worldPos);
  }
}
