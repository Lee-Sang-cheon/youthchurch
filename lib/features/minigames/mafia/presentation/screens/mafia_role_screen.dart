import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/mafia_enums.dart';
import '../mafia_game_notifier.dart';
import '../widgets/mafia_timer_ring.dart';

class MafiaRoleScreen extends ConsumerStatefulWidget {
  const MafiaRoleScreen({super.key});

  @override
  ConsumerState<MafiaRoleScreen> createState() => _MafiaRoleScreenState();
}

class _MafiaRoleScreenState extends ConsumerState<MafiaRoleScreen>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() => _revealed = true);
    _flipCtrl.forward();
  }

  static const _accent = Color(0xFFFF4D6A);

  Color _roleColor(MafiaRole? role) {
    switch (role) {
      case MafiaRole.mafia: return _accent;
      case MafiaRole.police: return AC.glass1;
      case MafiaRole.doctor: return AC.glass2;
      default: return AC.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mafiaGameProvider);
    final role = state.myRole;
    final roleColor = _roleColor(role);
    final timer = state.timerSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('역할 확인',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('${timer}초 후 게임 시작',
                            style: const TextStyle(
                                fontSize: 11, color: AC.muted)),
                      ],
                    ),
                  ),
                  _TimerRing(seconds: timer, total: 30),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _revealed ? null : _reveal,
                        child: AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (_, __) {
                            final isBack = _flipAnim.value > 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(
                                  _flipAnim.value * 3.14159),
                              child: isBack
                                  ? Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(3.14159),
                                      child: _RoleCard(
                                          role: role,
                                          roleColor: roleColor),
                                    )
                                  : _CardBack(roleColor: roleColor),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_revealed)
                        Text('카드를 탭해 역할을 확인하세요',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5)))
                      else if (role == MafiaRole.mafia &&
                          state.mafiaUids.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _accent.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text('동료 이단자',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _accent.withOpacity(0.8),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...state.players
                                  .where((p) =>
                                      state.mafiaUids.contains(p.userId) &&
                                      p.userId !=
                                          (state.myPlayer?.userId ?? ''))
                                  .map((p) => Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_rounded,
                                                color: _accent, size: 14),
                                            const SizedBox(width: 6),
                                            Text(p.nickname,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final Color roleColor;
  const _CardBack({required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1030),
            const Color(0xFF0D0920),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: roleColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded,
                color: roleColor.withOpacity(0.6), size: 56),
            const SizedBox(height: 12),
            Text('탭하여 역할 확인',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final MafiaRole? role;
  final Color roleColor;
  const _RoleCard({required this.role, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor.withOpacity(0.25),
            const Color(0xFF0D0920),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: roleColor.withOpacity(0.3),
              blurRadius: 32,
              spreadRadius: 4),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(role?.emoji ?? '👥',
              style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(role?.displayName ?? '시민',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: roleColor)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              role?.description ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AC.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final int seconds;
  final int total;
  const _TimerRing({required this.seconds, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? seconds / total : 0.0;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF4D6A)),
          ),
          Text('$seconds',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
