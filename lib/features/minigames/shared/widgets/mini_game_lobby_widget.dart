import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../models/game_room.dart';

class MiniGameLobbyWidget extends StatelessWidget {
  final String gameTitle;
  final Color color;
  final String roomCode;
  final List<GamePlayer> players;
  final bool isHost;
  final bool canStart; // host only, min players
  final bool isStarting;
  final VoidCallback onStart;
  final VoidCallback onLeave;
  final String? startHint; // e.g. "최소 3명 필요"

  const MiniGameLobbyWidget({
    super.key,
    required this.gameTitle,
    required this.color,
    required this.roomCode,
    required this.players,
    required this.isHost,
    required this.canStart,
    required this.isStarting,
    required this.onStart,
    required this.onLeave,
    this.startHint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onLeave,
                    child: Glass(
                      radius: 999,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(gameTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Room code
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Glass(
                radius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('방 코드',
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(roomCode,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6)),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: roomCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('코드가 복사됐어요'),
                                  duration: Duration(seconds: 1)),
                            );
                          },
                          child: Icon(Icons.copy_rounded, size: 20, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('이 코드를 친구에게 공유하세요',
                        style: const TextStyle(fontSize: 11, color: AC.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Players
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('참가자 ${players.length}명',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AC.muted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: players.length,
                itemBuilder: (_, i) {
                  final p = players[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p.isHost ? color.withOpacity(0.4) : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.2),
                          ),
                          child: Center(
                            child: Text(
                              p.nickname.isNotEmpty ? p.nickname[0] : '?',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: color),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('방장',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: color,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Start button (host only)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: isHost
                  ? Column(
                      children: [
                        if (startHint != null && !canStart)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(startHint!,
                                style: const TextStyle(fontSize: 12, color: AC.muted)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (canStart && !isStarting) ? onStart : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: color.withOpacity(0.25),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isStarting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('게임 시작',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
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
                          style: TextStyle(fontSize: 13, color: AC.muted)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
