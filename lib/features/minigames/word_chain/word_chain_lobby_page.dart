import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/game_room.dart';
import '../shared/widgets/mini_game_lobby_widget.dart';
import 'word_chain_notifier.dart';
import 'word_chain_play_page.dart';

class WordChainLobbyPage extends ConsumerWidget {
  const WordChainLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wordChainProvider);
    final notifier = ref.read(wordChainProvider.notifier);
    final myUid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isHost = state.players.any((p) => p.isHost && p.uid == myUid);

    ref.listen(wordChainProvider, (prev, next) {
      if (prev?.status != GameStatus.playing &&
          next.status == GameStatus.playing) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const WordChainPlayPage()));
      }
    });

    return MiniGameLobbyWidget(
      gameTitle: '끝말잇기',
      color: const Color(0xFF4ECDC4),
      roomCode: state.roomCode,
      players: state.players,
      isHost: isHost,
      canStart: state.players.length >= 1,
      isStarting: false,
      startHint: '최소 2명이 필요해요',
      onStart: () => notifier.startGame(),
      onLeave: () async {
        await notifier.leave();
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}
