import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../domain/avatar_user.dart';

class ChurchWebViewScene extends StatefulWidget {
  final String playerName;
  final Color playerColor;
  final void Function(double x, double y)? onMove;

  const ChurchWebViewScene({
    super.key,
    this.playerName = '나',
    this.playerColor = const Color(0xFFFFB44D),
    this.onMove,
  });

  @override
  State<ChurchWebViewScene> createState() => ChurchWebViewSceneState();
}

class ChurchWebViewSceneState extends State<ChurchWebViewScene> {
  late final WebViewController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080512))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            if (data['type'] == 'ready') {
              _ready = true;
            } else if (data['type'] == 'move') {
              widget.onMove?.call(
                (data['x'] as num).toDouble(),
                (data['y'] as num).toDouble(),
              );
            }
          } catch (_) {}
        },
      )
      ..loadFlutterAsset('assets/church_scene.html');
  }

  // 다른 유저 위치 업데이트
  void updateOtherUsers(List<AvatarUser> users) {
    if (!_ready) return;
    final list = users.map((u) => {
      'uid': u.uid,
      'name': u.name,
      'color': u.color.value.toRadixString(16).padLeft(8, '0').substring(2),
      'x': u.x,
      'y': u.y,
    }).toList();
    final json = jsonEncode(list).replaceAll("'", "\\'");
    _ctrl.runJavaScript("window.setOtherUsers('$json')");
  }

  // 내 위치 강제 이동 (presence 동기화용)
  void setPlayerPosition(double x, double y) {
    if (!_ready) return;
    _ctrl.runJavaScript("window.setPlayerPosition($x, $y)");
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _ctrl);
  }
}
