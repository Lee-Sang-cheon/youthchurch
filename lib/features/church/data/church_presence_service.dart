import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import '../domain/avatar_user.dart';

// ignore_for_file: unused_field

class ChurchPresenceService {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  Map<String, dynamic> _myPayload = {};
  Timer? _throttleTimer;

  final _controller = StreamController<List<AvatarUser>>.broadcast();
  Stream<List<AvatarUser>> get usersStream => _controller.stream;

  String? get _myUid => _client.auth.currentUser?.id;

  Future<String?> _getChurchId() async {
    final uid = _myUid;
    if (uid == null) return null;
    final res = await _client
        .from('users')
        .select('church_id')
        .eq('id', uid)
        .maybeSingle();
    return res?['church_id'] as String?;
  }

  Future<void> join({
    required String nickname,
    String? prayer,
    required double x,
    required double y,
    String room = 'hall',
  }) async {
    final uid = _myUid;
    if (uid == null) return;
    final churchId = await _getChurchId();
    if (churchId == null) return;

    _myPayload = {
      'uid': uid,
      'nickname': nickname,
      'prayer': prayer,
      'x': x,
      'y': y,
    };

    _channel = _client.channel('church_${room}:$churchId');
    _channel!
        .onPresenceSync((_) => _onSync())
        .onPresenceJoin((_) => _onSync())
        .onPresenceLeave((_) => _onSync())
        .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track(_myPayload);
      }
    });
  }

  void updatePosition(double x, double y) {
    _myPayload['x'] = x;
    _myPayload['y'] = y;
    _throttleTimer?.cancel();
    _throttleTimer = Timer(const Duration(milliseconds: 500), () {
      _channel?.track(_myPayload);
    });
  }

  Future<void> updatePrayer(String? prayer) async {
    _myPayload['prayer'] = prayer;
    await _channel?.track(_myPayload);
  }

  void _onSync() {
    final rawState = _channel?.presenceState();
    if (rawState == null) return;
    final state = rawState as List<SinglePresenceState>;
    final myUid = _myUid;
    final users = <AvatarUser>[];

    for (final single in state) {
      for (final presence in single.presences) {
        final p = presence.payload;
        final uid = p['uid'] as String?;
        if (uid == null || uid == myUid) continue;

        final colors = _colorFromUid(uid);
        users.add(AvatarUser(
          id: uid.hashCode.abs() % 100000,
          uid: uid,
          name: (p['nickname'] as String?) ?? '?',
          role: '',
          status: '',
          prayer: p['prayer'] as String?,
          color: colors.$1,
          color2: colors.$2,
          x: (p['x'] as num?)?.toDouble() ?? 50,
          y: (p['y'] as num?)?.toDouble() ?? 60,
        ));
      }
    }

    if (!_controller.isClosed) _controller.add(users);
  }

  static (Color, Color) _colorFromUid(String uid) {
    const pairs = [
      (Color(0xFF7C5CFF), Color(0xFFC5B6FF)),
      (Color(0xFF3BD6C6), Color(0xFFBDFFF4)),
      (Color(0xFFFF7EB6), Color(0xFFFFD2E7)),
      (Color(0xFFFFA14D), Color(0xFFFFE0B8)),
      (Color(0xFF5B9DFF), Color(0xFFCFE2FF)),
      (Color(0xFF9D8CFF), Color(0xFFDDD5FF)),
      (Color(0xFFFF9BB0), Color(0xFFFFE2E9)),
    ];
    final index = uid.hashCode.abs() % pairs.length;
    return pairs[index];
  }

  Future<void> leave() async {
    _throttleTimer?.cancel();
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
  }

  void dispose() {
    leave();
    _controller.close();
  }
}
