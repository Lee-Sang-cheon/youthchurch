import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/mafia_enums.dart';
import '../mafia_game_notifier.dart';

class MafiaEndScreen extends ConsumerWidget {
  const MafiaEndScreen({super.key});

  static const _accent = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mafiaGameProvider);
    final notifier = ref.read(mafiaGameProvider.notifier);
    final result = state.result;
    final isCitizenWin = result == GameResult.citizenWin;

    final winColor = isCitizenWin ? Colors.green : _accent;
    final winEmoji = isCitizenWin ? '🎉' : '🔫';
    final winText = isCitizenWin ? '성도 승리!' : '이단자 승리!';
    final winDesc = isCitizenWin
        ? '이단자를 모두 색출했습니다!'
        : '이단자가 교회를 장악했습니다!';

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // 결과 배너
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: winColor.withOpacity(0.15),
                border:
                    Border.all(color: winColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: winColor.withOpacity(0.2),
                      blurRadius: 32,
                      spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(winEmoji,
                    style: const TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 20),
            Text(winText,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: winColor)),
            const SizedBox(height: 8),
            Text(winDesc,
                style:
                    const TextStyle(fontSize: 15, color: AC.muted)),
            const SizedBox(height: 32),

            // 전체 직업 공개
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('최종 직업 공개',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AC.muted)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.players.length,
                itemBuilder: (_, i) {
                  final p = state.players[i];
                  final role = p.role;
                  final isMafia = role == MafiaRole.mafia;
                  final roleColor = isMafia ? _accent : AC.glass2;
                  final isAlive = p.isAlive;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMafia
                          ? _accent.withOpacity(0.08)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isMafia
                              ? _accent.withOpacity(0.3)
                              : Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: roleColor.withOpacity(0.15),
                          ),
                          child: Center(
                            child: Text(
                              p.nickname.isNotEmpty
                                  ? p.nickname[0]
                                  : '?',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(p.nickname,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isAlive
                                              ? Colors.white
                                              : Colors.white38)),
                                  if (!isAlive) ...[
                                    const SizedBox(width: 6),
                                    const Text('(사망)',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (role != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${role.emoji} ${role.displayName}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('나가기',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
