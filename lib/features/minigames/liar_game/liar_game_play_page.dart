import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../church/presentation/widgets/avatar_widgets.dart';
import 'liar_game_models.dart';
import 'liar_game_notifier.dart';

const _kAvatarColors = [
  [Color(0xFF7C5CFF), Color(0xFFC5B6FF)],
  [Color(0xFF3BD6C6), Color(0xFFBDFFF4)],
  [Color(0xFFFF7EB6), Color(0xFFFFD2E7)],
  [Color(0xFFFFA14D), Color(0xFFFFE0B8)],
  [Color(0xFF5B9DFF), Color(0xFFCFE2FF)],
  [Color(0xFF9D8CFF), Color(0xFFDDD5FF)],
  [Color(0xFFFF9BB0), Color(0xFFFFE2E9)],
];

class LiarGamePlayPage extends ConsumerStatefulWidget {
  const LiarGamePlayPage({super.key});

  @override
  ConsumerState<LiarGamePlayPage> createState() => _LiarGamePlayPageState();
}

class _LiarGamePlayPageState extends ConsumerState<LiarGamePlayPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

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
    final state = ref.watch(liarGameProvider);
    final notifier = ref.read(liarGameProvider.notifier);

    ref.listen(liarGameProvider, (_, next) {
      if (next.descriptions.isNotEmpty) _scrollToBottom();
    });

    if (state.phase == LiarPhase.result) {
      return _LiarResultPage(state: state, notifier: notifier);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state),
            _buildAvatarRow(state),
            const Divider(color: Colors.white10, height: 1),
            _buildRoleCard(state),
            Expanded(child: _buildMainContent(state, notifier)),
            _buildInputArea(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LiarGameState state) {
    String subtitle;
    switch (state.phase) {
      case LiarPhase.describing:
        final nick = _getNickname(state, state.currentTurnUid);
        subtitle = '설명 단계 • $nick의 차례';
      case LiarPhase.voting:
        subtitle = '투표 • ${state.votes.length}/${state.players.length}명 완료';
      case LiarPhase.liarGuess:
        subtitle = '라이어 추측';
      default:
        subtitle = '라이어 게임';
    }

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
                const Text('라이어 게임',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: AC.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarRow(LiarGameState state) {
    final lastDesc =
        state.descriptions.isNotEmpty ? state.descriptions.last : null;

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        itemCount: state.players.length,
        itemBuilder: (_, i) {
          final p = state.players[i];
          final isSelf = p.uid == _myUid;
          final isTurn = state.phase == LiarPhase.describing &&
              state.currentTurnUid == p.uid;
          final hasVoted = state.votes.containsKey(p.uid);
          final colors = _kAvatarColors[i % _kAvatarColors.length];
          final color = colors[0];
          final color2 = colors[1];
          final hasBubble = lastDesc != null && lastDesc.uid == p.uid;

          return SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 말풍선
                SizedBox(
                  height: 36,
                  child: hasBubble
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 72),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xDD1A1230),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Text(
                                lastDesc.text,
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
                // 이름태그
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                const SizedBox(height: 2),
                // 아바타
                AvatarBody(
                  color: color,
                  color2: color2,
                  style: AvatarStyle.blob,
                  highlight: isTurn,
                  self: isSelf,
                ),
                // 투표 완료 표시
                if (state.phase == LiarPhase.voting && hasVoted)
                  const Text('✓',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(LiarGameState state) {
    final isLiar = state.isLiar;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isLiar
              ? AC.glass3.withOpacity(0.1)
              : AC.glass2.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isLiar
                  ? AC.glass3.withOpacity(0.4)
                  : AC.glass2.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLiar
                    ? AC.glass3.withOpacity(0.2)
                    : AC.glass2.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLiar ? '라이어' : '시민',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isLiar ? AC.glass3 : AC.glass2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('카테고리: ${state.category}',
                    style: const TextStyle(fontSize: 11, color: AC.muted)),
                if (!isLiar && state.word != null)
                  Text('단어: ${state.word}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))
                else if (isLiar)
                  const Text('단어를 모릅니다. 들키지 마세요!',
                      style: TextStyle(fontSize: 12, color: AC.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(LiarGameState state, LiarGameNotifier notifier) {
    switch (state.phase) {
      case LiarPhase.describing:
        return _buildDescriptionLog(state);
      case LiarPhase.voting:
        return _buildVotingList(state, notifier);
      case LiarPhase.liarGuess:
        return _buildLiarGuessContent(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDescriptionLog(LiarGameState state) {
    if (state.descriptions.isEmpty) {
      final nick = _getNickname(state, state.currentTurnUid);
      return Center(
        child: Text(
          state.currentTurnUid == _myUid
              ? '첫 번째로 설명해보세요!'
              : '$nick이(가) 설명할 차례예요',
          style: const TextStyle(fontSize: 14, color: AC.muted),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: state.descriptions.length,
      itemBuilder: (_, i) {
        final d = state.descriptions[i];
        final isMine = d.uid == _myUid;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine
                ? AC.glass3.withOpacity(0.08)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isMine
                    ? AC.glass3.withOpacity(0.25)
                    : Colors.white12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AC.glass3.withOpacity(0.2)),
                child: Center(
                  child: Text(
                    d.nickname.isNotEmpty ? d.nickname[0] : '?',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AC.glass3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.nickname,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AC.muted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(d.text,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVotingList(LiarGameState state, LiarGameNotifier notifier) {
    final myVote = state.votes[_myUid];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: state.players.length,
      itemBuilder: (_, i) {
        final p = state.players[i];
        if (p.uid == _myUid) return const SizedBox.shrink();
        final selected = myVote == p.uid;
        return GestureDetector(
          onTap: myVote == null ? () => notifier.submitVote(p.uid) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? AC.glass3.withOpacity(0.15)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected
                      ? AC.glass3.withOpacity(0.6)
                      : Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AC.glass3.withOpacity(0.2)),
                  child: Center(
                    child: Text(
                      p.nickname.isNotEmpty ? p.nickname[0] : '?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AC.glass3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(p.nickname,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AC.glass3, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiarGuessContent(LiarGameState state) {
    final isLiar = state.liarUid == _myUid;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          isLiar
              ? '당신이 라이어입니다!\n제시어를 맞히면 역전할 수 있어요!'
              : '라이어가 제시어를 추측하고 있어요...\n두근두근!',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16, color: AC.muted, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildInputArea(LiarGameState state, LiarGameNotifier notifier) {
    switch (state.phase) {
      case LiarPhase.describing:
        return _buildDescribeInput(state, notifier);
      case LiarPhase.voting:
        return _buildVoteStatus(state);
      case LiarPhase.liarGuess:
        return _buildLiarGuessInput(state, notifier);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDescribeInput(LiarGameState state, LiarGameNotifier notifier) {
    final isMyTurn = state.currentTurnUid == _myUid;
    if (!isMyTurn) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${_getNickname(state, state.currentTurnUid)}이(가) 설명 중이에요...',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AC.muted),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0920),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Glass(
              radius: 12,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _inputCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: state.isLiar
                      ? '들키지 않게 설명해보세요...'
                      : '단어를 설명해보세요',
                  hintStyle:
                      const TextStyle(color: AC.muted, fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submitDescription(notifier),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _submitDescription(notifier),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AC.glass3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDescription(LiarGameNotifier notifier) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    notifier.submitDescription(text);
    _inputCtrl.clear();
  }

  Widget _buildVoteStatus(LiarGameState state) {
    final myVote = state.votes[_myUid];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: myVote == null
          ? const Text('라이어를 지목하세요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AC.glass3))
          : Text(
              '투표 완료 • ${state.votes.length}/${state.players.length}명 참여',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AC.muted)),
    );
  }

  Widget _buildLiarGuessInput(
      LiarGameState state, LiarGameNotifier notifier) {
    final isLiar = state.liarUid == _myUid;
    if (!isLiar) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('라이어가 추측 중입니다...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AC.muted)),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0920),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Glass(
              radius: 12,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _inputCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '제시어를 맞혀보세요!',
                  hintStyle: TextStyle(color: AC.muted, fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submitGuess(notifier),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _submitGuess(notifier),
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
    );
  }

  void _submitGuess(LiarGameNotifier notifier) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    notifier.submitLiarGuess(text);
    _inputCtrl.clear();
  }

  String _getNickname(LiarGameState state, String? uid) {
    if (uid == null) return '';
    if (uid == _myUid) return '나';
    return state.players
            .where((p) => p.uid == uid)
            .map((p) => p.nickname)
            .firstOrNull ??
        uid;
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

class _LiarResultPage extends ConsumerWidget {
  final LiarGameState state;
  final LiarGameNotifier notifier;

  const _LiarResultPage({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liarNick = state.players
            .where((p) => p.uid == state.liarUid)
            .map((p) => p.nickname)
            .firstOrNull ??
        '알 수 없음';
    final citizensWon = state.result == LiarResult.citizenWin;
    final word = state.word ?? '?';

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 결과 아이콘
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: citizensWon
                    ? Colors.green.withOpacity(0.15)
                    : AC.glass3.withOpacity(0.15),
                border: Border.all(
                    color: citizensWon
                        ? Colors.green.withOpacity(0.5)
                        : AC.glass3.withOpacity(0.5),
                    width: 2),
              ),
              child: Icon(
                citizensWon
                    ? Icons.people_rounded
                    : Icons.person_rounded,
                size: 44,
                color: citizensWon ? Colors.green : AC.glass3,
              ),
            ),
            // 결과 텍스트
            Text(
              citizensWon ? '시민 승리!' : '라이어 승리!',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: citizensWon ? Colors.green : AC.glass3),
            ),
            const SizedBox(height: 8),
            Text(
              citizensWon
                  ? '라이어가 잡혔어요!'
                  : '라이어가 살아남았어요!',
              style: const TextStyle(fontSize: 15, color: AC.muted),
            ),
            const SizedBox(height: 32),
            // 라이어 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Glass(
                radius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('라이어',
                            style:
                                TextStyle(fontSize: 12, color: AC.muted)),
                        Text(liarNick,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AC.glass3)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('제시어',
                            style:
                                TextStyle(fontSize: 12, color: AC.muted)),
                        Text(word,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                    if (state.liarGuess != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('라이어 추측',
                              style: TextStyle(
                                  fontSize: 12, color: AC.muted)),
                          Row(
                            children: [
                              Text(state.liarGuess!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(width: 6),
                              Icon(
                                citizensWon
                                    ? Icons.close_rounded
                                    : Icons.check_rounded,
                                color: citizensWon
                                    ? Colors.red
                                    : Colors.green,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                    backgroundColor: AC.glass3,
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
