class BibleQuestion {
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String? explanation;

  const BibleQuestion({
    required this.question,
    required this.choices,
    required this.answerIndex,
    this.explanation,
  });
}

const kBibleQuestions = [
  BibleQuestion(
    question: '예수님이 태어나신 곳은 어디인가요?',
    choices: ['나사렛', '예루살렘', '베들레헴', '갈릴리'],
    answerIndex: 2,
    explanation: '미가 5:2, 누가복음 2:4-7',
  ),
  BibleQuestion(
    question: '노아의 방주에 탄 동물은 각 종류마다 몇 마리씩이었나요?',
    choices: ['1마리', '2마리', '7마리', '12마리'],
    answerIndex: 1,
    explanation: '창세기 6:19 — 정결한 짐승은 7쌍, 부정한 짐승은 2마리씩 (7:2-3)',
  ),
  BibleQuestion(
    question: '예수님의 제자는 총 몇 명인가요?',
    choices: ['10명', '11명', '12명', '13명'],
    answerIndex: 2,
    explanation: '마태복음 10:1-4',
  ),
  BibleQuestion(
    question: '모세가 홍해를 건넌 사건은 어느 책에 기록되어 있나요?',
    choices: ['창세기', '레위기', '민수기', '출애굽기'],
    answerIndex: 3,
    explanation: '출애굽기 14장',
  ),
  BibleQuestion(
    question: '다윗이 골리앗을 쓰러뜨린 무기는 무엇인가요?',
    choices: ['칼', '창', '활', '물매'],
    answerIndex: 3,
    explanation: '사무엘상 17:49',
  ),
  BibleQuestion(
    question: '요나가 삼 일 밤낮을 보낸 곳은 어디인가요?',
    choices: ['감옥', '광야', '큰 물고기 뱃속', '동굴'],
    answerIndex: 2,
    explanation: '요나 1:17',
  ),
  BibleQuestion(
    question: '성경의 첫 번째 책은 무엇인가요?',
    choices: ['출애굽기', '창세기', '시편', '요한복음'],
    answerIndex: 1,
    explanation: '창세기는 구약성경의 첫 번째 책입니다.',
  ),
  BibleQuestion(
    question: '예수님이 세례를 받으신 강은 어디인가요?',
    choices: ['갈릴리 호수', '사해', '요단강', '기혼 강'],
    answerIndex: 2,
    explanation: '마태복음 3:13',
  ),
  BibleQuestion(
    question: '바울이 기독교인을 박해하다 회심한 사건이 일어난 곳은 어디로 가는 길이었나요?',
    choices: ['로마', '예루살렘', '다메섹', '안디옥'],
    answerIndex: 2,
    explanation: '사도행전 9:3',
  ),
  BibleQuestion(
    question: '성경에서 가장 짧은 구절은 무엇인가요?',
    choices: ['"하나님은 사랑이시라"', '"예수께서 눈물을 흘리시더라"', '"믿음, 소망, 사랑"', '"아멘"'],
    answerIndex: 1,
    explanation: '요한복음 11:35 — "예수께서 눈물을 흘리시더라"',
  ),
];
