import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import '../shared/models/game_room.dart';
import 'yang_sechan_models.dart';

final yangSechanProvider =
    NotifierProvider<YangSechanNotifier, YangSechanState>(
        YangSechanNotifier.new);

class YangSechanNotifier extends Notifier<YangSechanState> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  String get _myUid => _client.auth.currentUser?.id ?? '';
  String get _myNickname =>
      _client.auth.currentUser?.userMetadata?['nickname'] as String? ?? '나';
  String get myUid => _myUid;

  @override
  YangSechanState build() => YangSechanState.initial();

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
    _channel = _client.channel('mg_yang_$code');
    _channel!
        .onPresenceSync((_) => _syncPlayers())
        .onPresenceJoin((_) => _syncPlayers())
        .onPresenceLeave((_) => _syncPlayers())
        .onBroadcast(event: 'start_game', callback: _onStartGame)
        .onBroadcast(event: 'ask_question', callback: _onAskQuestion)
        .onBroadcast(event: 'answer_question', callback: _onAnswerQuestion)
        .onBroadcast(event: 'guess_attempt', callback: _onGuessAttempt)
        .onBroadcast(event: 'end_game', callback: _onEndGame)
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

  void setTopic(String topic) {
    state = state.copyWith(topic: topic);
  }

  // 호스트가 게임 시작 - 단어 배정
  Future<void> startGame() async {
    final rand = Random();
    final players = List<GamePlayer>.from(state.players)..shuffle(rand);
    final turnOrderUids = players.map((p) => p.uid).toList();

    // 주제에 맞는 단어 목록
    List<String> wordList;
    if (state.topic == '전체') {
      wordList = kYangTopics.values.expand((list) => list).toList();
    } else {
      wordList = kYangTopics[state.topic] ?? kYangTopics.values.first.toList();
    }
    wordList = List<String>.from(wordList)..shuffle(rand);

    // 각 플레이어에게 단어 배정
    final wordMap = <String, String>{};
    for (var i = 0; i < players.length; i++) {
      wordMap[players[i].uid] = wordList[i % wordList.length];
    }

    final payload = {
      'word_map': wordMap,
      'turn_order': turnOrderUids,
      'topic': state.topic,
    };
    await _channel!.sendBroadcastMessage(event: 'start_game', payload: payload);
    _onStartGame(payload);
  }

  void _onStartGame(Map<String, dynamic> payload) {
    final wordMap = Map<String, String>.from(
        (payload['word_map'] as Map?)?.map((k, v) => MapEntry(k as String, v as String)) ?? {});
    final turnOrder = List<String>.from(payload['turn_order'] as List? ?? []);
    final topic = payload['topic'] as String? ?? '전체';
    state = state.copyWith(
      status: GameStatus.playing,
      phase: YangPhase.playing,
      wordMap: wordMap,
      turnOrderUids: turnOrder,
      currentTurnIndex: 0,
      correctUids: [],
      logs: [],
      topic: topic,
      clearPending: true,
    );
  }

  // 질문하기
  Future<void> askQuestion(String toUid, String toNickname, String question) async {
    final payload = {
      'from_uid': _myUid,
      'from_nickname': _myNickname,
      'to_uid': toUid,
      'to_nickname': toNickname,
      'question': question,
    };
    await _channel!.sendBroadcastMessage(event: 'ask_question', payload: payload);
    _onAskQuestion(payload);
  }

  void _onAskQuestion(Map<String, dynamic> payload) {
    final entry = YangLogEntry(
      type: YangLogType.question,
      fromUid: payload['from_uid'] as String? ?? '',
      fromNickname: payload['from_nickname'] as String? ?? '',
      toUid: payload['to_uid'] as String?,
      toNickname: payload['to_nickname'] as String?,
      content: payload['question'] as String? ?? '',
    );
    state = state.copyWith(
      logs: [...state.logs, entry],
      pendingFromUid: payload['from_uid'] as String?,
      pendingToUid: payload['to_uid'] as String?,
      pendingQuestion: payload['question'] as String?,
    );
  }

  // 답변하기 (예/아니오)
  Future<void> answerQuestion(bool isYes) async {
    final payload = {
      'from_uid': _myUid,
      'from_nickname': _myNickname,
      'to_uid': state.pendingFromUid,
      'is_yes': isYes,
    };
    await _channel!.sendBroadcastMessage(event: 'answer_question', payload: payload);
    _onAnswerQuestion(payload);
  }

  void _onAnswerQuestion(Map<String, dynamic> payload) {
    final isYes = payload['is_yes'] as bool? ?? false;
    final entry = YangLogEntry(
      type: YangLogType.answer,
      fromUid: payload['from_uid'] as String? ?? '',
      fromNickname: payload['from_nickname'] as String? ?? '',
      toUid: payload['to_uid'] as String?,
      content: isYes ? '예' : '아니오',
    );
    // 답변 후 다음 턴으로
    final nextIndex = _nextTurnIndex(state.currentTurnIndex, state.correctUids);
    state = state.copyWith(
      logs: [...state.logs, entry],
      currentTurnIndex: nextIndex,
      clearPending: true,
    );
  }

  // 정답 시도
  Future<void> guessWord(String guess) async {
    final payload = {
      'from_uid': _myUid,
      'from_nickname': _myNickname,
      'guess': guess,
      'my_word': state.wordMap[_myUid] ?? '',
    };
    await _channel!.sendBroadcastMessage(event: 'guess_attempt', payload: payload);
    _onGuessAttempt(payload);
  }

  void _onGuessAttempt(Map<String, dynamic> payload) {
    final fromUid = payload['from_uid'] as String? ?? '';
    final fromNickname = payload['from_nickname'] as String? ?? '';
    final guess = payload['guess'] as String? ?? '';
    final myWord = payload['my_word'] as String? ?? '';
    final isCorrect = guess.trim() == myWord.trim();

    final entry = YangLogEntry(
      type: isCorrect ? YangLogType.guessCorrect : YangLogType.guessWrong,
      fromUid: fromUid,
      fromNickname: fromNickname,
      content: guess,
    );

    final updatedCorrect = isCorrect
        ? [...state.correctUids, fromUid]
        : state.correctUids;

    final nextIndex = _nextTurnIndex(state.currentTurnIndex, updatedCorrect);
    final allDone = state.turnOrderUids.every((uid) => updatedCorrect.contains(uid));

    state = state.copyWith(
      logs: [...state.logs, entry],
      correctUids: updatedCorrect,
      currentTurnIndex: nextIndex,
      phase: allDone ? YangPhase.result : YangPhase.playing,
      status: allDone ? GameStatus.finished : GameStatus.playing,
    );
  }

  // 방장 게임 종료
  Future<void> endGame() async {
    final payload = {'ended_by': _myUid};
    await _channel!.sendBroadcastMessage(event: 'end_game', payload: payload);
    _onEndGame(payload);
  }

  void _onEndGame(Map<String, dynamic> payload) {
    state = state.copyWith(
      phase: YangPhase.result,
      status: GameStatus.finished,
    );
  }

  int _nextTurnIndex(int currentIndex, List<String> correctUids) {
    if (state.turnOrderUids.isEmpty) return 0;
    int next = (currentIndex + 1) % state.turnOrderUids.length;
    int tries = 0;
    while (correctUids.contains(state.turnOrderUids[next]) &&
        tries < state.turnOrderUids.length) {
      next = (next + 1) % state.turnOrderUids.length;
      tries++;
    }
    return next;
  }

  Future<void> leave() async {
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
    state = YangSechanState.initial();
  }
}
