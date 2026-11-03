import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/glass.dart';
import '../mafia_game_notifier.dart';

class MafiaLobbyScreen extends ConsumerWidget {
  const MafiaLobbyScreen({super.key});

  static const _accent = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mafiaGameProvider);
    final notifier = ref.read(mafiaGameProvider.notifier);
    final playerCount = state.players.length;
    final canStart = playerCount >= 1 && playerCount <= 10 && state.isHost; // TODO: 테스트 후 4로 복원

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await notifier.leave();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Glass(
                      radius: 999,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('마피아 게임',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Glass(
                radius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('방 코드',
                        style: TextStyle(
                            fontSize: 12,
                            color: _accent.withOpacity(0.8),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(state.roomCode,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 6)),
                    const SizedBox(height: 4),
                    const Text('이 코드를 친구에게 공유하세요',
                        style: TextStyle(fontSize: 11, color: AC.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('참가자 $playerCount명',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AC.muted)),
                  const SizedBox(width: 8),
                  if (playerCount < 4 && state.isHost)
                    const Text('(최소 4명 필요)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.orange)),
                  if (playerCount > 10)
                    const Text('(최대 10명)',
                        style:
                            TextStyle(fontSize: 11, color: Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: playerCount,
                itemBuilder: (_, i) {
                  final p = state.players[i];
                  final isMe = p.userId == (ref.read(mafiaGameProvider).myPlayer?.userId ?? '');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: p.userId == state.hostId
                              ? _accent.withOpacity(0.4)
                              : Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent.withOpacity(0.2)),
                          child: Center(
                            child: Text(
                              p.nickname.isNotEmpty
                                  ? p.nickname[0]
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(p.nickname,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('나',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                        const Spacer(),
                        if (p.userId == state.hostId)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('방장',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: _accent,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: state.isHost
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canStart ? () => notifier.startGame() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _accent.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('게임 시작',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Text('방장이 게임을 시작할 때까지 기다려주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: AC.muted)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
