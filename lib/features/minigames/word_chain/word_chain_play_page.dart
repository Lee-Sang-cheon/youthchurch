import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import 'word_chain_models.dart';
import 'word_chain_notifier.dart';

class WordChainPlayPage extends ConsumerStatefulWidget {
  const WordChainPlayPage({super.key});

  @override
  ConsumerState<WordChainPlayPage> createState() => _WordChainPlayPageState();
}

class _WordChainPlayPageState extends ConsumerState<WordChainPlayPage> {
  final _wordCtrl = TextEditingController();

  String get _myUid =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _wordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordChainProvider);
    final notifier = ref.read(wordChainProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: switch (state.phase) {
          WordChainPhase.lobby => const SizedBox.shrink(),
          WordChainPhase.playing => _buildPlayingPhase(state, notifier),
          WordChainPhase.result => _buildResultPhase(state, notifier),
        },
      ),
    );
  }

  Widget _buildPlayingPhase(WordChainState state, WordChainNotifier notifier) {
    final currentPlayer = state.players.length > state.currentTurnIndex
        ? state.players[state.currentTurnIndex]
        : null;
    final isMyTurn = currentPlayer?.uid == _myUid;
    final lastWord = state.lastWord;
    final lastChar = lastWord != null && lastWord.isNotEmpty
        ? lastWord[lastWord.length - 1]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        // 현재 차례 + 마지막 글자
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (lastChar != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AC.glass2.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AC.glass2.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Text(lastChar,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AC.glass2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else
                  const SizedBox(width: 0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMyTurn ? '내 차례!' : '${currentPlayer?.nickname ?? ''}의 차례',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isMyTurn ? AC.light : Colors.white),
                      ),
                      if (lastChar != null)
                        Text('"$lastChar"로 시작하는 단어를 입력하세요',
                            style: const TextStyle(
                                fontSize: 12, color: AC.muted)),
                      if (lastChar == null)
                        const Text('첫 번째 단어를 입력하세요',
                            style: TextStyle(fontSize: 12, color: AC.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 단어 목록
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: state.entries.length,
            itemBuilder: (_, i) {
              final idx = state.entries.length - 1 - i;
              final e = state.entries[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: e.valid
                      ? Colors.white.withOpacity(0.05)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: e.valid ? Colors.white12 : Colors.red.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.valid
                              ? AC.glass2.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2)),
                      child: Center(
                        child: Text(
                          e.nickname.isNotEmpty ? e.nickname[0] : '?',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: e.valid ? AC.glass2 : Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.nickname,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AC.muted,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(e.word,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    if (!e.valid)
                      const Icon(Icons.cancel_rounded,
                          color: Colors.red, size: 18),
                  ],
                ),
              );
            },
          ),
        ),
        // 입력창
        if (isMyTurn)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: Glass(
                    radius: 12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _wordCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: lastChar != null ? '"$lastChar"로 시작하는 단어' : '첫 단어 입력',
                        hintStyle: const TextStyle(color: AC.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final text = _wordCtrl.text.trim();
                    if (text.isEmpty) return;
                    notifier.submitWord(text);
                    _wordCtrl.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AC.glass2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResultPhase(WordChainState state, WordChainNotifier notifier) {
    final loser = state.players
            .where((p) => p.uid == state.loserId)
            .map((p) => p.nickname)
            .firstOrNull ??
        '알 수 없음';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('게임 종료!',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 16),
        Text('탈락: $loser',
            style: const TextStyle(fontSize: 18, color: Colors.redAccent)),
        if (state.loseReason != null) ...[
          const SizedBox(height: 8),
          Text(state.loseReason!,
              style: const TextStyle(fontSize: 14, color: AC.muted)),
        ],
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () async {
            await notifier.leave();
            if (context.mounted) {
              Navigator.popUntil(context, (r) => r.isFirst);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: AC.glass2.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AC.glass2.withOpacity(0.5)),
            ),
            child: const Text('나가기',
                style: TextStyle(
                    fontSize: 15,
                    color: AC.glass2,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Glass(
                radius: 999,
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16)),
          ),
          const SizedBox(width: 12),
          const Text('끝말잇기',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
