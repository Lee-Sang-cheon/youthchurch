import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import '../shared/models/game_room.dart';
import 'word_chain_models.dart';

final wordChainProvider =
    NotifierProvider<WordChainNotifier, WordChainState>(
        WordChainNotifier.new);

class WordChainNotifier extends Notifier<WordChainState> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  String get _myUid => _client.auth.currentUser?.id ?? '';
  String get _myNickname =>
      _client.auth.currentUser?.userMetadata?['nickname'] as String? ?? '나';
  String get myUid => _myUid;

  @override
  WordChainState build() {
    ref.onDispose(() => _channel?.unsubscribe());
    return WordChainState.initial();
  }

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
    _channel = _client.channel('mg_word_$code');
    _channel!
        .onPresenceSync((_) => _syncPlayers())
        .onPresenceJoin((_) => _syncPlayers())
        .onPresenceLeave((_) => _syncPlayers())
        .onBroadcast(event: 'start_game', callback: _onStartGame)
        .onBroadcast(event: 'submit_word', callback: _onSubmitWord)
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
    final list = rawState as List<SinglePresenceState>;
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

  Future<void> startGame() async {
    await _channel!.sendBroadcastMessage(event: 'start_game', payload: {});
    _onStartGame({}); // 발신자는 자신의 broadcast를 받지 못하므로 직접 호출
  }

  void _onStartGame(Map<String, dynamic> payload) {
    state = state.copyWith(
      status: GameStatus.playing,
      phase: WordChainPhase.playing,
      entries: [],
      currentTurnIndex: 0,
      loserId: null,
      loseReason: null,
    );
  }

  Future<void> submitWord(String word) async {
    await _channel!.sendBroadcastMessage(event: 'submit_word', payload: {
      'uid': _myUid,
      'nickname': _myNickname,
      'word': word,
    });
  }

  void _onSubmitWord(Map<String, dynamic> payload) {
    final uid = payload['uid'] as String? ?? '';
    final nickname = payload['nickname'] as String? ?? '?';
    final word = payload['word'] as String? ?? '';

    // 끝말잇기 유효성 검사
    final last = state.lastWord;
    bool valid = true;
    String? reason;

    if (last != null && last.isNotEmpty) {
      final lastChar = last[last.length - 1];
      if (word.isEmpty || word[0] != lastChar) {
        valid = false;
        reason = '"${last[last.length - 1]}"로 시작해야 해요';
      }
    }

    // 이미 사용된 단어인지 확인
    if (valid) {
      final usedWords = state.entries.where((e) => e.valid).map((e) => e.word);
      if (usedWords.contains(word)) {
        valid = false;
        reason = '이미 사용된 단어예요';
      }
    }

    final entry = WordChainEntry(
      uid: uid,
      nickname: nickname,
      word: word,
      valid: valid,
    );

    final updated = [...state.entries, entry];
    final nextTurn = (state.currentTurnIndex + 1) % state.players.length;

    if (!valid) {
      state = state.copyWith(
        entries: updated,
        phase: WordChainPhase.result,
        status: GameStatus.finished,
        loserId: uid,
        loseReason: reason,
      );
    } else {
      state = state.copyWith(
        entries: updated,
        currentTurnIndex: nextTurn,
      );
    }
  }

  Future<void> leave() async {
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
    state = WordChainState.initial();
  }
}
