import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import 'liar_game_models.dart';
import 'liar_game_notifier.dart';
import 'liar_game_play_page.dart';

class LiarGameLobbyPage extends ConsumerWidget {
  const LiarGameLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liarGameProvider);
    final notifier = ref.read(liarGameProvider.notifier);
    final myUid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isHost = state.players.any((p) => p.isHost && p.uid == myUid);

    ref.listen(liarGameProvider, (prev, next) {
      if (prev?.phase == LiarPhase.lobby && next.phase == LiarPhase.describing) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LiarGamePlayPage()));
      }
    });

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
                  const Text('라이어 게임',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 방 코드
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
                            color: AC.glass3,
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
            // 카테고리 선택 (방장만)
            if (isHost) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('카테고리 선택',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AC.muted)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: wordRepository.categories.map((cat) {
                          final selected = state.category == cat;
                          return GestureDetector(
                            onTap: () => notifier.setCategory(cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AC.glass3.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selected
                                        ? AC.glass3.withOpacity(0.7)
                                        : Colors.white12),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          selected ? AC.glass3 : AC.muted)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 참가자 목록
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('참가자 ${state.players.length}명',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AC.muted)),
                  const SizedBox(width: 8),
                  if (state.players.length < 3 && isHost)
                    const Text('(최소 3명 필요)',
                        style: TextStyle(fontSize: 11, color: Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.players.length,
                itemBuilder: (_, i) {
                  final p = state.players[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: p.isHost
                              ? AC.glass3.withOpacity(0.4)
                              : Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AC.glass3.withOpacity(0.2)),
                          child: Center(
                            child: Text(
                              p.nickname.isNotEmpty ? p.nickname[0] : '?',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AC.glass3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(p.nickname,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        if (p.isHost) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AC.glass3.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('방장',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AC.glass3,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: isHost
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.players.isNotEmpty
                            ? () => notifier.startGame()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AC.glass3,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AC.glass3.withOpacity(0.25),
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
                          style:
                              TextStyle(fontSize: 13, color: AC.muted)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
