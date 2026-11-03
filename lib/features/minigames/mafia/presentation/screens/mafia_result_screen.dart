import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/mafia_enums.dart';
import '../mafia_game_notifier.dart';
import '../widgets/mafia_timer_ring.dart';

class MafiaResultScreen extends ConsumerWidget {
  const MafiaResultScreen({super.key});

  static const _accent = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mafiaGameProvider);

    // round_result: round는 이미 +1 됐으므로 이전 라운드 로그 조회
    final prevRound = state.round - 1;
    final executedLogs = state.roundLogs(prevRound)
        .where((l) => l.event == 'executed')
        .toList();
    final killedLogs = state.roundLogs(prevRound)
        .where((l) => l.event == 'killed')
        .toList();
    final savedLogs = state.roundLogs(prevRound)
        .where((l) => l.event == 'saved')
        .toList();

    final executedLog =
        executedLogs.isNotEmpty ? executedLogs.first : null;
    final executedRole = executedLog?.targetRole != null
        ? MafiaRole.fromKey(executedLog!.targetRole)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.white10))),
              child: Row(
                children: [
                  const Icon(Icons.summarize_rounded,
                      color: AC.light, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${state.round - 1}라운드 결과',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  MafiaTimerRing(
                      seconds: state.timerSeconds, total: 10),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 처형 결과
                    if (executedLog != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text('⚖️',
                                style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 12),
                            Text(
                              '${executedLog.targetNickname ?? ''}님이 처형되었습니다',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (executedRole != null)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange
                                      .withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${executedRole.emoji} ${executedRole.displayName}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange),
                                ),
                              )
                            else
                              const Text('처형 없음 (동표)',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AC.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          children: [
                            Text('🤷', style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Text('동표로 처형이 없었습니다',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 밤 결과 요약
                    if (killedLogs.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Text('☠️',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              '어젯밤 ${killedLogs.map((l) => l.targetNickname ?? '').join(', ')}님 사망',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                    if (savedLogs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Text('🛡️',
                                style: TextStyle(fontSize: 18)),
                            SizedBox(width: 10),
                            Text('중보기도자가 누군가를 지켰습니다',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    // 생존자 현황
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(
                          label: '생존',
                          value: '${state.alivePlayers.length}명',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: '다음 라운드',
                          value: '${state.round}라운드',
                          color: _accent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text('${state.timerSeconds}초 후 다음 밤이 시작됩니다',
                        style: const TextStyle(
                            fontSize: 12, color: AC.muted)),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}
