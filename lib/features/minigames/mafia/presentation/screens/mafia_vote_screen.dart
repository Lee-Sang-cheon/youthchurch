import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../mafia_game_notifier.dart';
import '../widgets/mafia_timer_ring.dart';

class MafiaVoteScreen extends ConsumerWidget {
  const MafiaVoteScreen({super.key});

  static const _accent = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mafiaGameProvider);
    final notifier = ref.read(mafiaGameProvider.notifier);
    final myPlayer = state.myPlayer;
    final isAlive = myPlayer?.isAlive ?? true;
    final myVote = state.myVote;
    final voteCount = state.voteCount;
    final alive = state.alivePlayers;
    final totalVotes = state.rawVotes.length;
    final totalAlive = alive.length;

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.white10))),
              child: Row(
                children: [
                  const Icon(Icons.how_to_vote_rounded,
                      color: AC.light, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('투표',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('이단자를 지목하세요 • $totalVotes/$totalAlive명 투표',
                            style: const TextStyle(
                                fontSize: 11, color: AC.muted)),
                      ],
                    ),
                  ),
                  MafiaTimerRing(
                      seconds: state.timerSeconds, total: 30),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (!isAlive)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text('사망했습니다. 투표를 관전하세요.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: AC.muted)),
              ),

            // 투표 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: alive.length,
                itemBuilder: (_, i) {
                  final p = alive[i];
                  final isSelf = p.userId == myPlayer?.userId;
                  final count = voteCount[p.userId] ?? 0;
                  final selected = myVote == p.userId;
                  final barWidth = totalAlive > 0
                      ? count / totalAlive
                      : 0.0;

                  return GestureDetector(
                    onTap: (isAlive && !isSelf && myVote == null)
                        ? () => notifier.submitVote(p.userId)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withOpacity(0.12)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected
                                ? _accent.withOpacity(0.5)
                                : isSelf
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            // 득표 바
                            if (count > 0)
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: barWidth,
                                    child: Container(
                                      color: _accent.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? _accent.withOpacity(0.25)
                                          : Colors.white
                                              .withOpacity(0.08),
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.nickname.isNotEmpty
                                            ? p.nickname[0]
                                            : '?',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: selected
                                                ? _accent
                                                : Colors.white70),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isSelf ? '${p.nickname} (나)' : p.nickname,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelf
                                            ? AC.muted
                                            : Colors.white),
                                  ),
                                  const Spacer(),
                                  if (count > 0)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            _accent.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text('$count표',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: _accent)),
                                    )
                                  else if (!isSelf && myVote == null && isAlive)
                                    const Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        color: Colors.white24,
                                        size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (myVote != null)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '투표 완료 • $totalVotes/$totalAlive명 참여',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
