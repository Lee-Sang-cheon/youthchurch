import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/widgets/mini_game_card.dart';
import '../liar_game/liar_game_entrance_page.dart';
import '../mafia/presentation/screens/mafia_hub_screen.dart';
import '../yang_sechan/yang_sechan_entrance_page.dart';
import '../bible_quiz/bible_quiz_play_page.dart';

class MinigamesHubPage extends StatelessWidget {
  const MinigamesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameInfo(
        title: '마피아 게임',
        description: '마피아를 찾아라! 밤에 협력하고 낮에 토론으로 색출하세요',
        icon: Icons.groups_rounded,
        color: const Color(0xFFFF4D6A),
        playerInfo: '4~10명',
        page: const MafiaHubScreen(),
      ),
      _GameInfo(
        title: '양세찬 게임',
        description: '이 사람은 누구? 단서를 주고 정체를 맞혀보세요',
        icon: Icons.person_search_rounded,
        color: AC.glass1,
        playerInfo: '3~10명',
        page: const YangSechanEntrancePage(),
      ),
      _GameInfo(
        title: '라이어 게임',
        description: '라이어를 찾아라! 시민은 주제를 설명하고 라이어를 찾아야 해요',
        icon: Icons.psychology_rounded,
        color: AC.glass3,
        playerInfo: '3~8명',
        page: const LiarGameEntrancePage(),
      ),
      _GameInfo(
        title: '성경 퀴즈',
        description: '성경 지식을 겨뤄보세요! 빠르고 정확하게 맞히는 사람이 이겨요',
        icon: Icons.menu_book_rounded,
        color: AC.light,
        playerInfo: '1~8명',
        page: const BibleQuizPlayPage(),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: games.length,
      itemBuilder: (context, i) {
        final g = games[i];
        return MiniGameCard(
          title: g.title,
          description: g.description,
          icon: g.icon,
          color: g.color,
          playerInfo: g.playerInfo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => g.page),
          ),
        );
      },
    );
  }
}

class _GameInfo {
  final String title, description, playerInfo;
  final IconData icon;
  final Color color;
  final Widget page;
  const _GameInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.playerInfo,
    required this.page,
  });
}
