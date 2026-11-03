import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mafia_enums.dart';
import 'mafia_game_notifier.dart';
import 'screens/mafia_lobby_screen.dart';
import 'screens/mafia_role_screen.dart';
import 'screens/mafia_night_screen.dart';
import 'screens/mafia_day_screen.dart';
import 'screens/mafia_vote_screen.dart';
import 'screens/mafia_result_screen.dart';
import 'screens/mafia_end_screen.dart';

class MafiaGameRouter extends ConsumerWidget {
  const MafiaGameRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(mafiaGameProvider.select((s) => s.phase));

    final Widget screen = switch (phase) {
      GamePhase.lobby => const MafiaLobbyScreen(),
      GamePhase.roleReveal => const MafiaRoleScreen(),
      GamePhase.night => const MafiaNightScreen(),
      GamePhase.day => const MafiaDayScreen(),
      GamePhase.voting => const MafiaVoteScreen(),
      GamePhase.roundResult => const MafiaResultScreen(),
      GamePhase.gameOver => const MafiaEndScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey(phase), child: screen),
    );
  }
}
