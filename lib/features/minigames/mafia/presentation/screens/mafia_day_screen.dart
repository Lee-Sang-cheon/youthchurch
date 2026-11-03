import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/glass.dart';
import '../mafia_game_notifier.dart';
import '../widgets/mafia_timer_ring.dart';

class MafiaDayScreen extends ConsumerStatefulWidget {
  const MafiaDayScreen({super.key});

  @override
  ConsumerState<MafiaDayScreen> createState() => _MafiaDayScreenState();
}

class _MafiaDayScreenState extends ConsumerState<MafiaDayScreen> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _accent = Color(0xFFFF4D6A);

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mafiaGameProvider);
    final notifier = ref.read(mafiaGameProvider.notifier);
    final alive = state.alivePlayers;
    final myPlayer = state.myPlayer;
    final isAlive = myPlayer?.isAlive ?? true;

    ref.listen(mafiaGameProvider, (_, next) {
      if (next.publicMessages.length != state.publicMessages.length) {
        _scrollToBottom();
      }
    });

    // 어젯밤 사망자
    final killedLogs = state.roundLogs(state.round)
        .where((l) => l.event == 'killed')
        .toList();
    final savedLogs = state.roundLogs(state.round)
        .where((l) => l.event == 'saved')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10))),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded,
                      color: AC.light, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('낮 페이즈 · ${state.round}라운드',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('생존자 ${alive.length}명',
                            style: const TextStyle(
                                fontSize: 11, color: AC.muted)),
                      ],
                    ),
                  ),
                  MafiaTimerRing(
                      seconds: state.timerSeconds, total: 90),
                ],
              ),
            ),

            // 사망자 공지
            if (killedLogs.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('☠️',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '지난 밤 ${killedLogs.map((l) => l.targetNickname ?? '').join(', ')}님이 사망했습니다',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            if (savedLogs.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Text('🛡️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('중보기도자가 누군가를 지켰습니다',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),

            // 생존자 목록 (가로 스크롤)
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: alive.length,
                itemBuilder: (_, i) {
                  final p = alive[i];
                  final isMe = p.userId == myPlayer?.userId;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe
                          ? _accent.withOpacity(0.15)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isMe
                              ? _accent.withOpacity(0.5)
                              : Colors.white12),
                    ),
                    child: Text(p.nickname,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isMe ? _accent : Colors.white70)),
                  );
                },
              ),
            ),

            const Divider(color: Colors.white10, height: 16),

            // 채팅 로그
            Expanded(
              child: state.publicMessages.isEmpty
                  ? const Center(
                      child: Text('자유롭게 토론하세요!\n이단자를 찾아내야 해요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: AC.muted,
                              height: 1.5)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 8),
                      itemCount: state.publicMessages.length,
                      itemBuilder: (_, i) {
                        final m = state.publicMessages[i];
                        final isMine = m.senderId ==
                            (myPlayer?.userId ?? '');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment: isMine
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(
                                      right: 8, top: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Colors.white.withOpacity(0.1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      m.nickname.isNotEmpty
                                          ? m.nickname[0]
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.w700),
                                    ),
                                  ),
                                ),
                              Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMine)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              bottom: 2),
                                      child: Text(m.nickname,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AC.muted,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                  Container(
                                    constraints:
                                        const BoxConstraints(
                                            maxWidth: 220),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? _accent.withOpacity(0.25)
                                          : Colors.white
                                              .withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: isMine
                                              ? _accent
                                                  .withOpacity(0.4)
                                              : Colors.white12),
                                    ),
                                    child: Text(m.content,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            height: 1.3)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 입력창
            if (isAlive)
              Container(
                padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0920),
                  border:
                      Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Glass(
                        radius: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: TextField(
                          controller: _chatCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: '토론에 참여하세요...',
                            hintStyle: TextStyle(
                                color: AC.muted, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _send(notifier),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _send(notifier),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.transparent,
                child: const Text(
                  '사망했습니다. 토론을 관전하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AC.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _send(notifier) {
    if (_chatCtrl.text.trim().isEmpty) return;
    notifier.sendPublicMessage(_chatCtrl.text.trim());
    _chatCtrl.clear();
  }
}
