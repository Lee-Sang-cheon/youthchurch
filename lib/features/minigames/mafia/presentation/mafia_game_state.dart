import '../domain/mafia_entities.dart';
import '../domain/mafia_enums.dart';

class MafiaGameState {
  final String roomId;
  final String roomCode;
  final String hostId;
  final String myUid;
  final GamePhase phase;
  final int round;
  final DateTime? phaseEndAt;
  final int timerSeconds;

  // Players
  final List<MafiaPlayer> players;
  final MafiaPlayer? myPlayer;

  // Chat
  final List<MafiaChatMessage> publicMessages;
  final List<MafiaChatMessage> mafiaMessages;

  // Night actions
  final bool myNightActionDone;
  final String? policeResult; // 'mafia' or 'citizen'

  // Voting
  final Map<String, String> rawVotes; // actorId → targetId
  final String? myVote;

  // Logs
  final List<MafiaGameLog> allLogs;

  // Result
  final GameResult? result;

  const MafiaGameState({
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    required this.myUid,
    required this.phase,
    required this.round,
    this.phaseEndAt,
    required this.timerSeconds,
    required this.players,
    this.myPlayer,
    required this.publicMessages,
    required this.mafiaMessages,
    required this.myNightActionDone,
    this.policeResult,
    required this.rawVotes,
    this.myVote,
    required this.allLogs,
    this.result,
  });

  factory MafiaGameState.initial() => const MafiaGameState(
        roomId: '',
        roomCode: '',
        hostId: '',
        myUid: '',
        phase: GamePhase.lobby,
        round: 0,
        timerSeconds: 0,
        players: [],
        publicMessages: [],
        mafiaMessages: [],
        myNightActionDone: false,
        rawVotes: {},
        allLogs: [],
      );

  bool get isHost => myUid == hostId && hostId.isNotEmpty;
  bool get isMyPlayerAlive => myPlayer?.isAlive ?? true;
  MafiaRole? get myRole => myPlayer?.role;
  List<String> get mafiaUids => myPlayer?.mafiaUids ?? [];

  List<MafiaPlayer> get alivePlayers =>
      players.where((p) => p.isAlive).toList();

  Map<String, int> get voteCount {
    final tally = <String, int>{};
    for (final target in rawVotes.values) {
      tally[target] = (tally[target] ?? 0) + 1;
    }
    return tally;
  }

  List<MafiaGameLog> roundLogs(int r) =>
      allLogs.where((l) => l.round == r).toList();

  static const _unset = Object();

  MafiaGameState copyWith({
    String? roomId,
    String? roomCode,
    String? hostId,
    String? myUid,
    GamePhase? phase,
    int? round,
    Object? phaseEndAt = _unset,
    int? timerSeconds,
    List<MafiaPlayer>? players,
    Object? myPlayer = _unset,
    List<MafiaChatMessage>? publicMessages,
    List<MafiaChatMessage>? mafiaMessages,
    bool? myNightActionDone,
    Object? policeResult = _unset,
    Map<String, String>? rawVotes,
    Object? myVote = _unset,
    List<MafiaGameLog>? allLogs,
    Object? result = _unset,
  }) =>
      MafiaGameState(
        roomId: roomId ?? this.roomId,
        roomCode: roomCode ?? this.roomCode,
        hostId: hostId ?? this.hostId,
        myUid: myUid ?? this.myUid,
        phase: phase ?? this.phase,
        round: round ?? this.round,
        phaseEndAt:
            phaseEndAt == _unset ? this.phaseEndAt : phaseEndAt as DateTime?,
        timerSeconds: timerSeconds ?? this.timerSeconds,
        players: players ?? this.players,
        myPlayer: myPlayer == _unset ? this.myPlayer : myPlayer as MafiaPlayer?,
        publicMessages: publicMessages ?? this.publicMessages,
        mafiaMessages: mafiaMessages ?? this.mafiaMessages,
        myNightActionDone: myNightActionDone ?? this.myNightActionDone,
        policeResult: policeResult == _unset
            ? this.policeResult
            : policeResult as String?,
        rawVotes: rawVotes ?? this.rawVotes,
        myVote: myVote == _unset ? this.myVote : myVote as String?,
        allLogs: allLogs ?? this.allLogs,
        result: result == _unset ? this.result : result as GameResult?,
      );
}
