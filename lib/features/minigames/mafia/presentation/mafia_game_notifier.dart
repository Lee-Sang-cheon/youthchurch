import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/mafia_repository.dart';
import '../data/mafia_repository_impl.dart';
import '../domain/mafia_entities.dart';
import '../domain/mafia_enums.dart';
import 'mafia_game_state.dart';

final mafiaGameProvider =
    NotifierProvider<MafiaGameNotifier, MafiaGameState>(MafiaGameNotifier.new);

class MafiaGameNotifier extends Notifier<MafiaGameState> {
  final _client = Supabase.instance.client;

  late MafiaRepository _repo;
  StreamSubscription? _roomStream;
  StreamSubscription? _playersStream;
  RealtimeChannel? _realtimeChannel;
  Timer? _timer;
  bool _resolving = false;

  String get _myUid => _client.auth.currentUser?.id ?? '';
  String get _myNickname =>
      _client.auth.currentUser?.userMetadata?['nickname'] as String? ?? '나';

  @override
  MafiaGameState build() {
    _repo = ref.read(mafiaRepositoryProvider);
    ref.onDispose(() {
      _cleanup();
    });
    return MafiaGameState.initial();
  }

  // ─── 방 생성 / 참가 ───────────────────────────────────────────

  Future<void> createRoom() async {
    final room = await _repo.createRoom(_myNickname);
    state = state.copyWith(
      roomId: room.id,
      roomCode: room.code,
      hostId: room.hostId,
      myUid: _myUid,
      phase: GamePhase.lobby,
    );
    await _subscribe(room.id);
    await _loadMyPlayer(room.id);
  }

  Future<void> joinRoom(String code) async {
    final room = await _repo.joinRoom(code, _myNickname);
    state = state.copyWith(
      roomId: room.id,
      roomCode: room.code,
      hostId: room.hostId,
      myUid: _myUid,
      phase: GamePhase.lobby,
    );
    await _subscribe(room.id);
    await _loadMyPlayer(room.id);
  }

  // ─── 구독 설정 ────────────────────────────────────────────────

  Future<void> _subscribe(String roomId) async {
    // Room 변경 구독
    _roomStream = _client
        .from('mafia_rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .listen((data) {
          if (data.isNotEmpty) {
            _onRoomUpdate(MafiaRoom.fromJson(data.first));
          }
        });

    // Players 구독
    _playersStream = _client
        .from('mafia_players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .listen((data) {
          final players =
              data.map((d) => MafiaPlayer.fromJson(d)).toList();
          state = state.copyWith(players: players);
        });

    // Chat / Log / Night action 구독 (Postgres Changes)
    _realtimeChannel = _client
        .channel('mafia_rt_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mafia_chat_messages',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: _onNewMessage,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mafia_game_logs',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: _onNewLog,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mafia_night_actions',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: _onNewNightAction,
        )
        .subscribe();
  }

  // ─── Room 업데이트 처리 ───────────────────────────────────────

  void _onRoomUpdate(MafiaRoom room) {
    final prevPhase = state.phase;
    final phaseChanged = prevPhase != room.phase;

    if (phaseChanged) {
      // 페이즈 전환 시 초기화
      state = state.copyWith(
        phase: room.phase,
        round: room.round,
        phaseEndAt: room.phaseEndAt,
        myNightActionDone: false,
        policeResult: null,
        myVote: null,
        rawVotes: const {},
      );
      _onPhaseEntered(room);
    } else {
      state = state.copyWith(
        phase: room.phase,
        round: room.round,
        phaseEndAt: room.phaseEndAt,
      );
    }

    // 타이머 재시작
    _timer?.cancel();
    if (room.phaseEndAt != null) {
      _startTimer(room.phaseEndAt!);
    }
  }

  void _onPhaseEntered(MafiaRoom room) {
    switch (room.phase) {
      case GamePhase.roleReveal:
        _loadMyPlayer(room.id);
      case GamePhase.night:
        _loadMyPlayer(room.id);
      case GamePhase.day:
        _loadMessages(room.id, ChatType.public);
        if (state.myPlayer?.role == MafiaRole.mafia) {
          _loadMessages(room.id, ChatType.mafia);
        }
      case GamePhase.voting:
        break;
      case GamePhase.roundResult:
        break;
      case GamePhase.gameOver:
        _timer?.cancel();
        _loadAllPlayers(room.id);
      default:
        break;
    }
    _resolving = false;
  }

  // ─── 타이머 ───────────────────────────────────────────────────

  void _startTimer(DateTime endAt) {
    _updateTimer(endAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimer(endAt);
    });
  }

  void _updateTimer(DateTime endAt) {
    final remaining = endAt.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      state = state.copyWith(timerSeconds: 0);
      _onTimerExpired();
    } else {
      state = state.copyWith(timerSeconds: remaining);
    }
  }

  void _onTimerExpired() {
    if (!state.isHost || _resolving) return;
    _resolving = true;

    switch (state.phase) {
      case GamePhase.roleReveal:
        _transitionToNight();
      case GamePhase.night:
        _resolveNight();
      case GamePhase.day:
        _transitionToVoting();
      case GamePhase.voting:
        _resolveVote();
      case GamePhase.roundResult:
        _startNextNight();
      default:
        _resolving = false;
    }
  }

  Future<void> _transitionToNight() async {
    try {
      await _repo.transitionPhase(
        roomId: state.roomId,
        phase: 'night',
        phaseEndAt: DateTime.now().add(const Duration(seconds: 60)),
      );
    } catch (_) {
      _resolving = false;
    }
  }

  Future<void> _resolveNight() async {
    try {
      await _repo.resolveNight(state.roomId, state.round);
    } catch (_) {
      _resolving = false;
    }
  }

  Future<void> _transitionToVoting() async {
    try {
      await _repo.transitionPhase(
        roomId: state.roomId,
        phase: 'voting',
        phaseEndAt: DateTime.now().add(const Duration(seconds: 30)),
      );
    } catch (_) {
      _resolving = false;
    }
  }

  Future<void> _resolveVote() async {
    try {
      await _repo.resolveVote(state.roomId, state.round);
    } catch (_) {
      _resolving = false;
    }
  }

  Future<void> _startNextNight() async {
    try {
      await _repo.transitionPhase(
        roomId: state.roomId,
        phase: 'night',
        phaseEndAt: DateTime.now().add(const Duration(seconds: 60)),
      );
    } catch (_) {
      _resolving = false;
    }
  }

  // ─── 게임 액션 ────────────────────────────────────────────────

  Future<void> startGame() async {
    await _repo.startGame(state.roomId);
  }

  Future<void> submitNightAction(String targetId, ActionType actionType) async {
    await _repo.submitNightAction(
      roomId: state.roomId,
      round: state.round,
      targetId: targetId,
      actionType: actionType,
    );
    state = state.copyWith(myNightActionDone: true);

    // 경찰이면 결과 조회
    if (actionType == ActionType.policeInvestigate) {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await _repo.getPoliceResult(state.roomId, state.round);
      if (result != null) {
        state = state.copyWith(policeResult: result);
      }
    }
  }

  Future<void> submitVote(String targetId) async {
    await _repo.submitVote(
      roomId: state.roomId,
      round: state.round,
      targetId: targetId,
    );
    final updated = Map<String, String>.from(state.rawVotes)..[_myUid] = targetId;
    state = state.copyWith(myVote: targetId, rawVotes: updated);
  }

  Future<void> sendPublicMessage(String content) async {
    await _repo.sendChatMessage(
      roomId: state.roomId,
      content: content,
      chatType: ChatType.public,
      round: state.round,
      nickname: state.myPlayer?.nickname ?? _myNickname,
    );
  }

  Future<void> sendMafiaMessage(String content) async {
    await _repo.sendChatMessage(
      roomId: state.roomId,
      content: content,
      chatType: ChatType.mafia,
      round: state.round,
      nickname: state.myPlayer?.nickname ?? _myNickname,
    );
  }

  // ─── Realtime 콜백 ────────────────────────────────────────────

  void _onNewMessage(PostgresChangePayload payload) {
    final msg = MafiaChatMessage.fromJson(payload.newRecord);
    if (msg.chatType == ChatType.public) {
      state = state.copyWith(
          publicMessages: [...state.publicMessages, msg]);
    } else if (msg.chatType == ChatType.mafia &&
        state.myPlayer?.role == MafiaRole.mafia) {
      state = state.copyWith(
          mafiaMessages: [...state.mafiaMessages, msg]);
    }
  }

  void _onNewLog(PostgresChangePayload payload) {
    final log = MafiaGameLog.fromJson(payload.newRecord);
    state = state.copyWith(allLogs: [...state.allLogs, log]);
  }

  void _onNewNightAction(PostgresChangePayload payload) {
    final action = payload.newRecord;
    if (action['action_type'] == ActionType.dayVote.key) {
      final actorId = action['actor_id'] as String;
      final targetId = action['target_id'] as String;
      final updated = Map<String, String>.from(state.rawVotes)..[actorId] = targetId;
      state = state.copyWith(rawVotes: updated);
    }
  }

  // ─── 데이터 로딩 ──────────────────────────────────────────────

  Future<void> _loadMyPlayer(String roomId) async {
    try {
      final player = await _repo.getMyPlayer(roomId);
      state = state.copyWith(myPlayer: player);
    } catch (_) {}
  }

  Future<void> _loadAllPlayers(String roomId) async {
    try {
      final players = await _repo.getPlayers(roomId);
      state = state.copyWith(players: players);
    } catch (_) {}
  }

  Future<void> _loadMessages(String roomId, ChatType type) async {
    try {
      final msgs = await _repo.getMessages(roomId, type, state.round);
      if (type == ChatType.public) {
        state = state.copyWith(publicMessages: msgs);
      } else {
        state = state.copyWith(mafiaMessages: msgs);
      }
    } catch (_) {}
  }

  // ─── 나가기 & 정리 ────────────────────────────────────────────

  Future<void> leave() async {
    _cleanup();
    try {
      await _repo.leaveRoom(state.roomId);
    } catch (_) {}
    state = MafiaGameState.initial();
  }

  void _cleanup() {
    _timer?.cancel();
    _roomStream?.cancel();
    _playersStream?.cancel();
    _realtimeChannel?.unsubscribe();
    _timer = null;
    _roomStream = null;
    _playersStream = null;
    _realtimeChannel = null;
  }
}
