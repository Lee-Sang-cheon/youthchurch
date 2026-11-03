import '../shared/models/game_room.dart';

enum YangPhase { lobby, playing, result }

enum YangLogType { question, answer, guessCorrect, guessWrong }

const kYangTopics = {
  '전체': <String>[],
  '캐릭터': [
    '미키마우스', '도라에몽', '스폰지밥', '피카츄', '엘사', '아이언맨',
    '해리포터', '배트맨', '슈퍼맨', '심바', '토이스토리 우디', '포켓몬 이상해씨',
  ],
  '연예인': [
    'BTS RM', 'BTS 뷔', 'IU', '박보검', '손흥민', '김연아',
    '싸이', '블랙핑크 제니', '유재석', '이효리', '강호동', '아이유',
  ],
  '위인': [
    '세종대왕', '이순신', '아인슈타인', '뉴턴', '링컨', '간디',
    '나폴레옹', '스티브잡스', '테슬라', '레오나르도 다빈치', '율곡 이이', '퀴리 부인',
  ],
  '인플루언서': [
    '침착맨', '쯔양', '양팡', '보겸', '대도서관', '허팝',
    '워크맨 장성규', '피식대학', '빠니보틀', '핏블리',
  ],
};

class YangLogEntry {
  final YangLogType type;
  final String fromUid;
  final String fromNickname;
  final String? toUid;
  final String? toNickname;
  final String content;

  const YangLogEntry({
    required this.type,
    required this.fromUid,
    required this.fromNickname,
    this.toUid,
    this.toNickname,
    required this.content,
  });
}

class YangSechanState {
  final String roomCode;
  final List<GamePlayer> players;
  final GameStatus status;
  final YangPhase phase;
  final String topic;
  final Map<String, String> wordMap; // uid → assigned word
  final List<String> turnOrderUids;
  final int currentTurnIndex;
  final List<String> correctUids; // 정답 맞힌 플레이어들
  final List<YangLogEntry> logs;
  final String? pendingFromUid; // 질문한 플레이어
  final String? pendingToUid;   // 답변해야 하는 플레이어
  final String? pendingQuestion;

  const YangSechanState({
    required this.roomCode,
    required this.players,
    required this.status,
    required this.phase,
    required this.topic,
    required this.wordMap,
    required this.turnOrderUids,
    required this.currentTurnIndex,
    required this.correctUids,
    required this.logs,
    this.pendingFromUid,
    this.pendingToUid,
    this.pendingQuestion,
  });

  factory YangSechanState.initial() => const YangSechanState(
        roomCode: '',
        players: [],
        status: GameStatus.lobby,
        phase: YangPhase.lobby,
        topic: '전체',
        wordMap: {},
        turnOrderUids: [],
        currentTurnIndex: 0,
        correctUids: [],
        logs: [],
      );

  String? get currentTurnUid =>
      turnOrderUids.isNotEmpty && currentTurnIndex < turnOrderUids.length
          ? turnOrderUids[currentTurnIndex]
          : null;

  bool get allCorrect =>
      turnOrderUids.isNotEmpty &&
      turnOrderUids.every((uid) => correctUids.contains(uid));

  YangSechanState copyWith({
    String? roomCode,
    List<GamePlayer>? players,
    GameStatus? status,
    YangPhase? phase,
    String? topic,
    Map<String, String>? wordMap,
    List<String>? turnOrderUids,
    int? currentTurnIndex,
    List<String>? correctUids,
    List<YangLogEntry>? logs,
    String? pendingFromUid,
    String? pendingToUid,
    String? pendingQuestion,
    bool clearPending = false,
  }) =>
      YangSechanState(
        roomCode: roomCode ?? this.roomCode,
        players: players ?? this.players,
        status: status ?? this.status,
        phase: phase ?? this.phase,
        topic: topic ?? this.topic,
        wordMap: wordMap ?? this.wordMap,
        turnOrderUids: turnOrderUids ?? this.turnOrderUids,
        currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
        correctUids: correctUids ?? this.correctUids,
        logs: logs ?? this.logs,
        pendingFromUid: clearPending ? null : (pendingFromUid ?? this.pendingFromUid),
        pendingToUid: clearPending ? null : (pendingToUid ?? this.pendingToUid),
        pendingQuestion: clearPending ? null : (pendingQuestion ?? this.pendingQuestion),
      );
}
