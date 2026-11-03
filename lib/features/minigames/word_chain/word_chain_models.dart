import '../shared/models/game_room.dart';

enum WordChainPhase { lobby, playing, result }

class WordChainEntry {
  final String uid;
  final String nickname;
  final String word;
  final bool valid;

  const WordChainEntry({
    required this.uid,
    required this.nickname,
    required this.word,
    required this.valid,
  });
}

class WordChainState {
  final String roomCode;
  final List<GamePlayer> players;
  final GameStatus status;
  final WordChainPhase phase;
  final List<WordChainEntry> entries;
  final int currentTurnIndex;
  final String? loserId;
  final String? loseReason;

  const WordChainState({
    required this.roomCode,
    required this.players,
    required this.status,
    required this.phase,
    required this.entries,
    required this.currentTurnIndex,
    this.loserId,
    this.loseReason,
  });

  factory WordChainState.initial() => const WordChainState(
        roomCode: '',
        players: [],
        status: GameStatus.lobby,
        phase: WordChainPhase.lobby,
        entries: [],
        currentTurnIndex: 0,
      );

  String? get lastWord =>
      entries.where((e) => e.valid).map((e) => e.word).lastOrNull;

  WordChainState copyWith({
    String? roomCode,
    List<GamePlayer>? players,
    GameStatus? status,
    WordChainPhase? phase,
    List<WordChainEntry>? entries,
    int? currentTurnIndex,
    String? loserId,
    String? loseReason,
  }) =>
      WordChainState(
        roomCode: roomCode ?? this.roomCode,
        players: players ?? this.players,
        status: status ?? this.status,
        phase: phase ?? this.phase,
        entries: entries ?? this.entries,
        currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
        loserId: loserId ?? this.loserId,
        loseReason: loseReason ?? this.loseReason,
      );
}
