import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/game_room.dart';
import 'liar_game_models.dart';

final liarGameProvider =
    NotifierProvider<LiarGameNotifier, LiarGameState>(LiarGameNotifier.new);

class LiarGameNotifier extends Notifier<LiarGameState> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  String get _myUid => _client.auth.currentUser?.id ?? '';
  String get _myNickname =>
      _client.auth.currentUser?.userMetadata?['nickname'] as String? ?? '나';
  String get myUid => _myUid;

  @override
  LiarGameState build() => LiarGameState.initial();

  Future<void> createRoom() async {
    final code = generateRoomCode();
    state = state.copyWith(roomCode: code);
    await _joinChannel(code, isHost: true);
  }

  Future<void> joinRoom(String code) async {
    state = state.copyWith(roomCode: code.toUpperCase());
    await _joinChannel(code.toUpperCase(), isHost: false);
  }

  Future<void> _joinChannel(String code, {required bool isHost}) async {
    _channel?.unsubscribe();
    _channel = _client.channel('mg_liar_$code');
    _channel!
        .onPresenceSync((_) => _syncPlayers())
        .onPresenceJoin((_) => _syncPlayers())
        .onPresenceLeave((_) => _syncPlayers())
        .onBroadcast(event: 'start_game', callback: _onStartGame)
        .onBroadcast(event: 'submit_desc', callback: _onSubmitDesc)
        .onBroadcast(event: 'submit_vote', callback: _onSubmitVote)
        .onBroadcast(event: 'liar_guess', callback: _onLiarGuess)
        .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'uid': _myUid,
          'nickname': _myNickname,
          'is_host': isHost,
        });
      }
    });
  }

  void _syncPlayers() {
    final rawState = _channel?.presenceState();
    if (rawState == null) return;
    final list = rawState;
    final players = <GamePlayer>[];
    for (final s in list) {
      for (final p in s.presences) {
        final d = p.payload;
        players.add(GamePlayer(
          uid: d['uid'] as String? ?? '',
          nickname: d['nickname'] as String? ?? '?',
          isHost: d['is_host'] as bool? ?? false,
        ));
      }
    }
    state = state.copyWith(players: players);
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  // 게임 시작 (호스트)
  Future<void> startGame() async {
    final rand = Random();
    final players = List<GamePlayer>.from(state.players)..shuffle(rand);
    final turnOrderUids = players.map((p) => p.uid).toList();

    // 라이어 선정
    final liarUid = turnOrderUids[rand.nextInt(turnOrderUids.length)];

    // 제시어 선택
    final words = wordRepository.getWords(state.category);
    final word = words[rand.nextInt(words.length)];

    // 각 플레이어에게 개별 전송
    Map<String, dynamic>? myPayload;
    for (final uid in turnOrderUids) {
      final payload = {
        'target_uid': uid,
        'role': uid == liarUid ? 'liar' : 'citizen',
        'category': state.category,
        'word': uid == liarUid ? null : word,
        'liar_uid': liarUid,
        'turn_order': turnOrderUids,
      };
      await _channel!.sendBroadcastMessage(event: 'start_game', payload: payload);
      if (uid == _myUid) myPayload = payload;
    }
    if (myPayload != null) _onStartGame(myPayload);
  }

  void _onStartGame(Map<String, dynamic> payload) {
    final targetUid = payload['target_uid'] as String?;
    if (targetUid != _myUid) return;
    final turnOrder = List<String>.from(payload['turn_order'] as List? ?? []);
    state = state.copyWith(
      status: GameStatus.playing,
      phase: LiarPhase.describing,
      myRole: payload['role'] as String?,
      category: payload['category'] as String? ?? state.category,
      word: payload['word'] as String?,
      liarUid: payload['liar_uid'] as String?,
      turnOrderUids: turnOrder,
      currentTurnIndex: 0,
      descriptions: [],
      votes: {},
      mostVotedUid: null,
      liarGuess: null,
      result: null,
    );
  }

  // 설명 제출
  Future<void> submitDescription(String text) async {
    final payload = {
      'uid': _myUid,
      'nickname': _myNickname,
      'text': text,
    };
    await _channel!.sendBroadcastMessage(event: 'submit_desc', payload: payload);
    _onSubmitDesc(payload);
  }

  void _onSubmitDesc(Map<String, dynamic> payload) {
    final desc = LiarDescription(
      uid: payload['uid'] as String? ?? '',
      nickname: payload['nickname'] as String? ?? '?',
      text: payload['text'] as String? ?? '',
    );
    final updated = [...state.descriptions, desc];
    final nextTurn = state.currentTurnIndex + 1;
    final allDone = nextTurn >= state.turnOrderUids.length;
    state = state.copyWith(
      descriptions: updated,
      currentTurnIndex: allDone ? state.currentTurnIndex : nextTurn,
      phase: allDone ? LiarPhase.voting : LiarPhase.describing,
    );
  }

  // 투표 제출
  Future<void> submitVote(String targetUid) async {
    final payload = {
      'voter': _myUid,
      'target': targetUid,
    };
    await _channel!.sendBroadcastMessage(event: 'submit_vote', payload: payload);
    _onSubmitVote(payload);
  }

  void _onSubmitVote(Map<String, dynamic> payload) {
    final voter = payload['voter'] as String? ?? '';
    final target = payload['target'] as String? ?? '';
    final updated = Map<String, String>.from(state.votes)..[voter] = target;

    if (updated.length >= state.players.length) {
      // 최다 득표자 계산
      final tally = <String, int>{};
      for (final t in updated.values) {
        tally[t] = (tally[t] ?? 0) + 1;
      }
      final mostVoted = tally.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      if (mostVoted == state.liarUid) {
        // 라이어 지목됨 → 라이어 추측 기회
        state = state.copyWith(
          votes: updated,
          mostVotedUid: mostVoted,
          phase: LiarPhase.liarGuess,
        );
      } else {
        // 라이어 지목 안됨 → 라이어 승
        state = state.copyWith(
          votes: updated,
          mostVotedUid: mostVoted,
          phase: LiarPhase.result,
          status: GameStatus.finished,
          result: LiarResult.liarWin,
        );
      }
    } else {
      state = state.copyWith(votes: updated);
    }
  }

  // 라이어 제시어 추측
  Future<void> submitLiarGuess(String guess) async {
    final payload = {
      'guess': guess,
      'word': state.word ?? '',
    };
    await _channel!.sendBroadcastMessage(event: 'liar_guess', payload: payload);
    _onLiarGuess(payload);
  }

  void _onLiarGuess(Map<String, dynamic> payload) {
    final guess = payload['guess'] as String? ?? '';
    final word = payload['word'] as String? ?? state.word ?? '';
    final correct = guess.trim() == word.trim();
    state = state.copyWith(
      liarGuess: guess,
      word: word, // 라이어도 이제 단어를 알게 됨
      phase: LiarPhase.result,
      status: GameStatus.finished,
      result: correct ? LiarResult.liarWin : LiarResult.citizenWin,
    );
  }

  Future<void> leave() async {
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
    state = LiarGameState.initial();
  }
}
