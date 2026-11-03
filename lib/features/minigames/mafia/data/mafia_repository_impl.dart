import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/game_room.dart';
import '../domain/mafia_entities.dart';
import '../domain/mafia_enums.dart';
import 'mafia_repository.dart';

final mafiaRepositoryProvider = Provider<MafiaRepository>(
  (_) => SupabaseMafiaRepository(),
);

class SupabaseMafiaRepository implements MafiaRepository {
  final _client = Supabase.instance.client;

  String get _myUid => _client.auth.currentUser?.id ?? '';
  String get _myNickname =>
      _client.auth.currentUser?.userMetadata?['nickname'] as String? ?? '나';

  @override
  Future<MafiaRoom> createRoom(String nickname) async {
    final code = generateRoomCode();

    final roomData = await _client.from('mafia_rooms').insert({
      'code': code,
      'host_id': _myUid,
      'status': 'waiting',
      'phase': 'lobby',
      'round': 0,
    }).select().single();

    final room = MafiaRoom.fromJson(roomData);

    await _client.from('mafia_players').insert({
      'room_id': room.id,
      'user_id': _myUid,
      'nickname': nickname.isNotEmpty ? nickname : _myNickname,
      'is_alive': true,
    });

    return room;
  }

  @override
  Future<MafiaRoom> joinRoom(String code, String nickname) async {
    final roomData = await _client
        .from('mafia_rooms')
        .select()
        .eq('code', code.toUpperCase())
        .eq('status', 'waiting')
        .single();

    final room = MafiaRoom.fromJson(roomData);

    await _client.from('mafia_players').upsert(
      {
        'room_id': room.id,
        'user_id': _myUid,
        'nickname': nickname.isNotEmpty ? nickname : _myNickname,
        'is_alive': true,
      },
      onConflict: 'room_id,user_id',
    );

    return room;
  }

  @override
  Future<void> startGame(String roomId) async {
    await _client.functions.invoke(
      'mafia-start-game',
      body: {'room_id': roomId},
    );
  }

  @override
  Future<MafiaPlayer> getMyPlayer(String roomId) async {
    final data = await _client
        .from('mafia_players')
        .select()
        .eq('room_id', roomId)
        .eq('user_id', _myUid)
        .single();
    return MafiaPlayer.fromJson(data);
  }

  @override
  Future<List<MafiaPlayer>> getPlayers(String roomId) async {
    final data = await _client
        .from('mafia_players')
        .select()
        .eq('room_id', roomId)
        .order('created_at');
    return (data as List).map((d) => MafiaPlayer.fromJson(d as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MafiaChatMessage>> getMessages(
      String roomId, ChatType type, int round) async {
    final data = await _client
        .from('mafia_chat_messages')
        .select()
        .eq('room_id', roomId)
        .eq('chat_type', type == ChatType.mafia ? 'mafia' : 'public')
        .order('created_at');
    return (data as List)
        .map((d) => MafiaChatMessage.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MafiaGameLog>> getLogs(String roomId, int round) async {
    final data = await _client
        .from('mafia_game_logs')
        .select()
        .eq('room_id', roomId)
        .eq('round', round)
        .order('created_at');
    return (data as List)
        .map((d) => MafiaGameLog.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitNightAction({
    required String roomId,
    required int round,
    required String targetId,
    required ActionType actionType,
  }) async {
    await _client.from('mafia_night_actions').upsert(
      {
        'room_id': roomId,
        'round': round,
        'actor_id': _myUid,
        'target_id': targetId,
        'action_type': actionType.key,
      },
      onConflict: 'room_id,round,actor_id,action_type',
    );
  }

  @override
  Future<void> sendChatMessage({
    required String roomId,
    required String content,
    required ChatType chatType,
    required int round,
    required String nickname,
  }) async {
    await _client.from('mafia_chat_messages').insert({
      'room_id': roomId,
      'sender_id': _myUid,
      'nickname': nickname,
      'content': content,
      'chat_type': chatType == ChatType.mafia ? 'mafia' : 'public',
      'round': round,
    });
  }

  @override
  Future<void> submitVote({
    required String roomId,
    required int round,
    required String targetId,
  }) async {
    await _client.from('mafia_night_actions').upsert(
      {
        'room_id': roomId,
        'round': round,
        'actor_id': _myUid,
        'target_id': targetId,
        'action_type': ActionType.dayVote.key,
      },
      onConflict: 'room_id,round,actor_id,action_type',
    );
  }

  @override
  Future<String?> getPoliceResult(String roomId, int round) async {
    final data = await _client
        .from('mafia_night_actions')
        .select('result')
        .eq('room_id', roomId)
        .eq('round', round)
        .eq('actor_id', _myUid)
        .eq('action_type', ActionType.policeInvestigate.key)
        .maybeSingle();
    return data?['result'] as String?;
  }

  @override
  Future<void> resolveNight(String roomId, int round) async {
    await _client.functions.invoke(
      'mafia-night-resolve',
      body: {'room_id': roomId, 'round': round},
    );
  }

  @override
  Future<void> resolveVote(String roomId, int round) async {
    await _client.functions.invoke(
      'mafia-vote-resolve',
      body: {'room_id': roomId, 'round': round},
    );
  }

  @override
  Future<void> transitionPhase({
    required String roomId,
    required String phase,
    required DateTime phaseEndAt,
    int? round,
  }) async {
    final update = <String, dynamic>{
      'phase': phase,
      'phase_end_at': phaseEndAt.toUtc().toIso8601String(),
    };
    if (round != null) update['round'] = round;
    await _client.from('mafia_rooms').update(update).eq('id', roomId);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await _client
        .from('mafia_players')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', _myUid);
  }
}
