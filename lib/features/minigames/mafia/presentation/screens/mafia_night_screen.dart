import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/glass.dart';
import '../../domain/mafia_enums.dart';
import '../mafia_game_notifier.dart';
import '../widgets/mafia_timer_ring.dart';

class MafiaNightScreen extends ConsumerStatefulWidget {
  const MafiaNightScreen({super.key});

  @override
  ConsumerState<MafiaNightScreen> createState() => _MafiaNightScreenState();
}

class _MafiaNightScreenState extends ConsumerState<MafiaNightScreen> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _selectedTargetId;

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
    final role = state.myRole;

    ref.listen(mafiaGameProvider, (_, next) {
      if (next.mafiaMessages.length != state.mafiaMessages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF060414),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state),
            Expanded(
              child: switch (role) {
                MafiaRole.mafia => _buildMafiaView(state, notifier),
                MafiaRole.police => _buildPoliceView(state, notifier),
                MafiaRole.doctor => _buildDoctorView(state, notifier),
                _ => _buildCitizenView(state),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nights_stay_rounded,
              color: Color(0xFF9D8CFF), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('밤 페이즈',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          MafiaTimerRing(
              seconds: state.timerSeconds, total: 60),
        ],
      ),
    );
  }

  // ─── 마피아 뷰 ────────────────────────────────────────────────

  Widget _buildMafiaView(state, notifier) {
    final alive = state.alivePlayers
        .where((p) => !state.mafiaUids.contains(p.userId))
        .toList();

    return Column(
      children: [
        // 마피아 채팅
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D6A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFFF4D6A).withOpacity(0.25)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFFFF4D6A), size: 14),
              SizedBox(width: 6),
              Text('이단자 전용 채팅',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF4D6A),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: state.mafiaMessages.isEmpty
              ? const Center(
                  child: Text('동료와 작전을 짜세요...',
                      style: TextStyle(fontSize: 12, color: AC.muted)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  itemCount: state.mafiaMessages.length,
                  itemBuilder: (_, i) {
                    final m = state.mafiaMessages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${m.nickname}: ',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFF4D6A),
                                  fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: m.content,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // 채팅 입력
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Glass(
                  radius: 10,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 2),
                  child: TextField(
                    controller: _chatCtrl,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '이단자 채팅...',
                      hintStyle:
                          TextStyle(color: AC.muted, fontSize: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (_chatCtrl.text.trim().isEmpty) return;
                  notifier.sendMafiaMessage(_chatCtrl.text.trim());
                  _chatCtrl.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 20),
        // 제거 대상 투표
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.how_to_vote_rounded,
                  color: Color(0xFFFF4D6A), size: 16),
              const SizedBox(width: 6),
              const Text('제거 대상 선택',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              if (state.myNightActionDone)
                const Text('투표 완료',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: state.myNightActionDone
              ? const Center(
                  child: Text('투표 완료! 다른 이단자의 결정을 기다리는 중...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AC.muted)))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alive.length,
                  itemBuilder: (_, i) {
                    final p = alive[i];
                    final selected = _selectedTargetId == p.userId;
                    return GestureDetector(
                      onTap: () async {
                        setState(() => _selectedTargetId = p.userId);
                        await notifier.submitNightAction(
                            p.userId, ActionType.mafiaVote);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFF4D6A)
                                  .withOpacity(0.15)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected
                                  ? const Color(0xFFFF4D6A)
                                      .withOpacity(0.6)
                                  : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text(p.nickname,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFFFF4D6A), size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── 경찰 뷰 ──────────────────────────────────────────────────

  Widget _buildPoliceView(state, notifier) {
    final policeResult = state.policeResult;
    final alive = state.alivePlayers
        .where((p) => p.userId != (state.myPlayer?.userId ?? ''))
        .toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AC.glass1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AC.glass1.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('👮', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('목자의 분별',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Text('1명을 조사해 이단자 여부를 확인하세요',
                        style: TextStyle(
                            fontSize: 11, color: AC.muted)),
                    if (policeResult != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: policeResult == 'mafia'
                              ? Colors.red.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          policeResult == 'mafia'
                              ? '이단자입니다!'
                              : '시민입니다',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: policeResult == 'mafia'
                                  ? Colors.red
                                  : Colors.green),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!state.myNightActionDone)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: alive.length,
              itemBuilder: (_, i) {
                final p = alive[i];
                return GestureDetector(
                  onTap: () async {
                    setState(() => _selectedTargetId = p.userId);
                    await notifier.submitNightAction(
                        p.userId, ActionType.policeInvestigate);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Text(p.nickname,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.search_rounded,
                            color: AC.glass1, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text('조사 완료! 결과를 확인하세요.',
                  style: TextStyle(fontSize: 13, color: AC.muted)),
            ),
          ),
      ],
    );
  }

  // ─── 의사 뷰 ──────────────────────────────────────────────────

  Widget _buildDoctorView(state, notifier) {
    final alive = state.alivePlayers.toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AC.glass2.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AC.glass2.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Text('💊', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('중보기도',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('1명을 선택해 오늘 밤 이단자의 공격을 막아주세요',
                        style: TextStyle(
                            fontSize: 11, color: AC.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!state.myNightActionDone)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: alive.length,
              itemBuilder: (_, i) {
                final p = alive[i];
                return GestureDetector(
                  onTap: () async {
                    setState(() => _selectedTargetId = p.userId);
                    await notifier.submitNightAction(
                        p.userId, ActionType.doctorProtect);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Text(p.nickname,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.shield_rounded,
                            color: AC.glass2, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text('보호 완료! 아침이 밝아오길 기다리세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AC.muted)),
            ),
          ),
      ],
    );
  }

  // ─── 시민 뷰 ──────────────────────────────────────────────────

  Widget _buildCitizenView(state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Center(
                child: Text('😴',
                    style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('밤이 되었습니다',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text('눈을 감으세요\n이단자가 움직이고 있어요...',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AC.muted, height: 1.6)),
            const SizedBox(height: 24),
            MafiaTimerRing(
                seconds: state.timerSeconds, total: 60),
          ],
        ),
      ),
    );
  }
}
