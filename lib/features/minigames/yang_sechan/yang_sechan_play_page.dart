import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../church/presentation/widgets/avatar_widgets.dart';
import 'yang_sechan_models.dart';
import 'yang_sechan_notifier.dart';

const _kAvatarColors = [
  [Color(0xFF7C5CFF), Color(0xFFC5B6FF)],
  [Color(0xFF3BD6C6), Color(0xFFBDFFF4)],
  [Color(0xFFFF7EB6), Color(0xFFFFD2E7)],
  [Color(0xFFFFA14D), Color(0xFFFFE0B8)],
  [Color(0xFF5B9DFF), Color(0xFFCFE2FF)],
  [Color(0xFF9D8CFF), Color(0xFFDDD5FF)],
  [Color(0xFFFF9BB0), Color(0xFFFFE2E9)],
];

class YangSechanPlayPage extends ConsumerStatefulWidget {
  const YangSechanPlayPage({super.key});

  @override
  ConsumerState<YangSechanPlayPage> createState() =>
      _YangSechanPlayPageState();
}

class _YangSechanPlayPageState extends ConsumerState<YangSechanPlayPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _selectedTargetUid;
  bool _isGuessMode = false;

  String get _myUid =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(yangSechanProvider);
    final notifier = ref.read(yangSechanProvider.notifier);

    ref.listen(yangSechanProvider, (_, next) {
      if (next.logs.isNotEmpty) _scrollToBottom();
      if (next.phase == YangPhase.result) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => YangSechanResultPage()),
        );
      }
    });

    if (state.phase == YangPhase.result) {
      return YangSechanResultPage();
    }

    final isMyTurn = state.currentTurnUid == _myUid;
    final iNeedToAnswer =
        state.pendingToUid == _myUid && state.pendingFromUid != null;
    final myWord = state.wordMap[_myUid] ?? '???';
    final isCorrect = state.correctUids.contains(_myUid);

    final otherPlayers = state.players
        .where((p) => !state.correctUids.contains(p.uid))
        .where((p) => state.players.length == 1 || p.uid != _myUid)
        .toList();

    // 대상이 1명뿐이면 자동 선택
    if (otherPlayers.length == 1 && _selectedTargetUid == null) {
      _selectedTargetUid = otherPlayers.first.uid;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(state, notifier),
            // 플레이어 카드 (가로 스크롤)
            _buildPlayerCards(state),
            const Divider(color: Colors.white10, height: 1),
            // 채팅 로그
            Expanded(
              child: state.logs.isEmpty
                  ? Center(
                      child: Text(
                        isMyTurn
                            ? '첫 번째 질문을 해보세요!'
                            : '${_getNickname(state, state.currentTurnUid)}의 차례예요',
                        style:
                            const TextStyle(fontSize: 14, color: AC.muted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.logs.length,
                      itemBuilder: (_, i) =>
                          _buildLogEntry(state.logs[i], myWord),
                    ),
            ),
            // 입력 영역
            _buildInputArea(
                state, notifier, isMyTurn, iNeedToAnswer, isCorrect, otherPlayers),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(YangSechanState state, YangSechanNotifier notifier) {
    final myUid = _myUid;
    final isHost = state.players.any((p) => p.isHost && p.uid == myUid);
    final currentNick = _getNickname(state, state.currentTurnUid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          Glass(
            radius: 999,
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('양세찬 게임',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('${state.topic} • 현재 턴: $currentNick',
                    style:
                        const TextStyle(fontSize: 11, color: AC.muted)),
              ],
            ),
          ),
          if (isHost)
            GestureDetector(
              onTap: () => _showEndGameDialog(notifier),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: const Text('게임 종료',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCards(YangSechanState state) {
    // 최근 로그 기반으로 버블 표시
    final lastLog = state.logs.isNotEmpty ? state.logs.last : null;

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: state.players.length,
        itemBuilder: (_, i) {
          final p = state.players[i];
          final isSelf = p.uid == _myUid;
          final word = isSelf ? '???' : (state.wordMap[p.uid] ?? '?');
          final isCorrect = state.correctUids.contains(p.uid);
          final isTurn = state.currentTurnUid == p.uid;
          final colors = _kAvatarColors[i % _kAvatarColors.length];
          final color = colors[0];
          final color2 = colors[1];

          // 이 플레이어가 마지막 로그의 발신자인지
          final hasBubble = lastLog != null &&
              (lastLog.fromUid == p.uid || lastLog.toUid == p.uid);
          String? bubbleText;
          if (hasBubble && lastLog != null) {
            if (lastLog.fromUid == p.uid) {
              bubbleText = lastLog.type == YangLogType.question
                  ? lastLog.content
                  : lastLog.content;
            } else if (lastLog.toUid == p.uid &&
                lastLog.type == YangLogType.answer) {
              bubbleText = lastLog.content;
            }
          }

          return SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 말풍선
                SizedBox(
                  height: 40,
                  child: bubbleText != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 72),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xDD1A1230),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Text(
                                bubbleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(8, 4),
                              painter: _BubbleTail(),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                // 캐릭터 + 이름 + 단어
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 이름태그
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isTurn
                                ? color.withOpacity(0.9)
                                : const Color(0x990E0B1A),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: isTurn
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.14)),
                          ),
                          child: Text(
                            p.nickname,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isTurn
                                    ? const Color(0xFF1A1030)
                                    : Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // 아바타 바디
                        AvatarBody(
                          color: color,
                          color2: color2,
                          style: AvatarStyle.blob,
                          highlight: isTurn,
                          self: isSelf,
                        ),
                        const SizedBox(height: 2),
                        // 제시어
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelf
                                ? Colors.white.withOpacity(0.06)
                                : color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isSelf
                                    ? Colors.white12
                                    : color.withOpacity(0.4)),
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isSelf ? AC.muted : color2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // 정답 오버레이
                    if (isCorrect)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('✓',
                                style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogEntry(YangLogEntry entry, String myWord) {
    final isMine = entry.fromUid == _myUid;
    Color color;
    IconData icon;
    String label;

    switch (entry.type) {
      case YangLogType.question:
        color = AC.glass1;
        icon = Icons.help_outline_rounded;
        label =
            '${entry.fromNickname} → ${entry.toNickname ?? '?'}: ${entry.content}';
      case YangLogType.answer:
        color = entry.content == '예' ? Colors.green : Colors.orange;
        icon = entry.content == '예'
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;
        label = '${entry.fromNickname}: ${entry.content}';
      case YangLogType.guessCorrect:
        color = Colors.green;
        icon = Icons.stars_rounded;
        label = '${entry.fromNickname}가 정답 맞힘! → "${entry.content}"';
      case YangLogType.guessWrong:
        color = Colors.red;
        icon = Icons.close_rounded;
        label =
            '${entry.fromNickname}의 정답 시도 실패: "${entry.content}"';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isMine ? Colors.white : Colors.white70,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    YangSechanState state,
    YangSechanNotifier notifier,
    bool isMyTurn,
    bool iNeedToAnswer,
    bool isCorrect,
    List otherPlayers,
  ) {
    // 정답 맞힌 경우
    if (isCorrect) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.green.withOpacity(0.08),
        child: const Text('정답을 맞혔어요! 다른 플레이어들을 기다려주세요 😊',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.green)),
      );
    }

    // 답변해야 하는 경우
    if (iNeedToAnswer) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0920),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${state.pendingQuestion}"',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.answerQuestion(true),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Center(
                        child: Text('예',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.green)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.answerQuestion(false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: const Center(
                        child: Text('아니오',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 내 턴이 아닌 경우
    if (!isMyTurn) {
      final currentNick = _getNickname(
          ref.read(yangSechanProvider), state.currentTurnUid);
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.transparent,
        child: Text('$currentNick의 차례예요. 기다려주세요...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AC.muted)),
      );
    }

    // 내 턴 - 질문하기 / 정답 시도
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0920),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 모드 선택 탭
          Row(
            children: [
              _modeTab('질문하기', !_isGuessMode, () {
                setState(() {
                  _isGuessMode = false;
                  _selectedTargetUid = null;
                  _inputCtrl.clear();
                });
              }),
              const SizedBox(width: 8),
              _modeTab('정답 시도', _isGuessMode, () {
                setState(() {
                  _isGuessMode = true;
                  _selectedTargetUid = null;
                  _inputCtrl.clear();
                });
              }),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isGuessMode) ...[
            // 대상 선택
            if (otherPlayers.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: otherPlayers.map((p) {
                    final selected = _selectedTargetUid == p.uid;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedTargetUid = p.uid),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AC.glass1.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? AC.glass1.withOpacity(0.7)
                                  : Colors.white12),
                        ),
                        child: Text(p.nickname,
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    selected ? AC.glass1 : Colors.white70,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // 질문 입력
            Row(
              children: [
                Expanded(
                  child: Glass(
                    radius: 12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _inputCtrl,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '예/아니오로 답할 수 있는 질문을 하세요',
                        hintStyle: TextStyle(color: AC.muted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_selectedTargetUid == null || _inputCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('대상을 선택하고 질문을 입력해주세요'),
                            duration: Duration(seconds: 1)),
                      );
                      return;
                    }
                    final target = state.players
                        .firstWhere((p) => p.uid == _selectedTargetUid);
                    notifier.askQuestion(
                        target.uid, target.nickname, _inputCtrl.text.trim());
                    setState(() {
                      _selectedTargetUid = null;
                      _inputCtrl.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AC.glass1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 정답 시도 입력
            Row(
              children: [
                Expanded(
                  child: Glass(
                    radius: 12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _inputCtrl,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '내 제시어가 뭔지 입력해보세요!',
                        hintStyle: TextStyle(color: AC.muted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_inputCtrl.text.trim().isEmpty) return;
                    notifier.guessWord(_inputCtrl.text.trim());
                    setState(() {
                      _isGuessMode = false;
                      _inputCtrl.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AC.glass1.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AC.glass1.withOpacity(0.7) : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AC.glass1 : AC.muted)),
      ),
    );
  }

  String _getNickname(YangSechanState state, String? uid) {
    if (uid == null) return '';
    if (uid == _myUid) return '나';
    return state.players
            .where((p) => p.uid == uid)
            .map((p) => p.nickname)
            .firstOrNull ??
        uid;
  }

  void _showEndGameDialog(YangSechanNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1030),
        title: const Text('게임 종료',
            style: TextStyle(color: Colors.white)),
        content: const Text('게임을 종료하시겠어요?',
            style: TextStyle(color: AC.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AC.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.endGame();
            },
            child: const Text('종료',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _BubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xDD1A1230);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// 결과 화면
class YangSechanResultPage extends ConsumerWidget {
  const YangSechanResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(yangSechanProvider);
    final notifier = ref.read(yangSechanProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Text('게임 결과',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.players.length,
                itemBuilder: (_, i) {
                  final p = state.players[i];
                  final word = state.wordMap[p.uid] ?? '?';
                  final correct = state.correctUids.contains(p.uid);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: correct
                          ? Colors.green.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: correct
                              ? Colors.green.withOpacity(0.4)
                              : Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AC.glass1.withOpacity(0.2)),
                          child: Center(
                            child: Text(
                              p.nickname.isNotEmpty ? p.nickname[0] : '?',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AC.glass1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nickname,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              Text('제시어: $word',
                                  style: const TextStyle(
                                      fontSize: 12, color: AC.muted)),
                            ],
                          ),
                        ),
                        Icon(
                          correct
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: correct ? Colors.green : Colors.white24,
                          size: 24,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await notifier.leave();
                    if (context.mounted) {
                      Navigator.popUntil(context, (r) => r.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AC.glass1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('나가기',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
