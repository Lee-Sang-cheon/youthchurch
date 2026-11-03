import '../shared/models/game_room.dart';

enum LiarPhase { lobby, describing, voting, liarGuess, result }

enum LiarResult { citizenWin, liarWin }

// 카테고리별 제시어 — 나중에 SupabaseWordRepository로 교체 가능
abstract class WordRepository {
  List<String> getWords(String category);
  List<String> get categories;
}

class LocalWordRepository implements WordRepository {
  static const _data = <String, List<String>>{
    '음식': ['피자', '라면', '김치찌개', '초밥', '치킨', '떡볶이', '삼겹살', '파스타', '햄버거', '냉면', '짜장면', '순대'],
    '직업': ['의사', '선생님', '요리사', '경찰관', '소방관', '프로그래머', '가수', '배우', '변호사', '간호사', '기자', '디자이너'],
    '장소': ['도서관', '수영장', '공항', '놀이공원', '병원', '학교', '카페', '편의점', '헬스장', '영화관', '기차역', '백화점'],
    '연예인': ['BTS RM', '아이유', '박보검', '손흥민', '블랙핑크 제니', '유재석', '이효리', '강호동', '싸이', 'BTS 뷔'],
    '동물': ['강아지', '고양이', '코끼리', '기린', '펭귄', '호랑이', '곰', '원숭이', '토끼', '햄스터'],
  };

  @override
  List<String> getWords(String category) =>
      List<String>.from(_data[category] ?? []);

  @override
  List<String> get categories => _data.keys.toList();
}

final wordRepository = LocalWordRepository();

class LiarDescription {
  final String uid;
  final String nickname;
  final String text;

  const LiarDescription({
    required this.uid,
    required this.nickname,
    required this.text,
  });
}

class LiarGameState {
  final String roomCode;
  final List<GamePlayer> players;
  final GameStatus status;
  final LiarPhase phase;
  final String category;
  final String? word; // 시민만 앎, 라이어는 null
  final String? myRole; // 'liar' | 'citizen'
  final String? liarUid;
  final List<LiarDescription> descriptions;
  final List<String> turnOrderUids;
  final int currentTurnIndex;
  final Map<String, String> votes; // voterUid → targetUid
  final String? mostVotedUid;
  final String? liarGuess;
  final LiarResult? result;

  const LiarGameState({
    required this.roomCode,
    required this.players,
    required this.status,
    required this.phase,
    required this.category,
    this.word,
    this.myRole,
    this.liarUid,
    required this.descriptions,
    required this.turnOrderUids,
    required this.currentTurnIndex,
    required this.votes,
    this.mostVotedUid,
    this.liarGuess,
    this.result,
  });

  factory LiarGameState.initial() => const LiarGameState(
        roomCode: '',
        players: [],
        status: GameStatus.lobby,
        phase: LiarPhase.lobby,
        category: '음식',
        descriptions: [],
        turnOrderUids: [],
        currentTurnIndex: 0,
        votes: {},
      );

  bool get isLiar => myRole == 'liar';

  String? get currentTurnUid =>
      turnOrderUids.isNotEmpty && currentTurnIndex < turnOrderUids.length
          ? turnOrderUids[currentTurnIndex]
          : null;

  LiarGameState copyWith({
    String? roomCode,
    List<GamePlayer>? players,
    GameStatus? status,
    LiarPhase? phase,
    String? category,
    String? word,
    String? myRole,
    String? liarUid,
    List<LiarDescription>? descriptions,
    List<String>? turnOrderUids,
    int? currentTurnIndex,
    Map<String, String>? votes,
    String? mostVotedUid,
    String? liarGuess,
    LiarResult? result,
  }) =>
      LiarGameState(
        roomCode: roomCode ?? this.roomCode,
        players: players ?? this.players,
        status: status ?? this.status,
        phase: phase ?? this.phase,
        category: category ?? this.category,
        word: word ?? this.word,
        myRole: myRole ?? this.myRole,
        liarUid: liarUid ?? this.liarUid,
        descriptions: descriptions ?? this.descriptions,
        turnOrderUids: turnOrderUids ?? this.turnOrderUids,
        currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
        votes: votes ?? this.votes,
        mostVotedUid: mostVotedUid ?? this.mostVotedUid,
        liarGuess: liarGuess ?? this.liarGuess,
        result: result ?? this.result,
      );
}
