import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/avatar_user.dart';
import '../../../home/data/prayer_repository.dart';
import '../../../home/data/challenge_repository.dart';

enum AvatarStyle { blob, figure, orb }

class AvatarFigure extends StatefulWidget {
  final AvatarUser user;
  final AvatarStyle style;
  final bool selected;
  final VoidCallback? onTap;
  final int seed;

  const AvatarFigure({
    super.key,
    required this.user,
    this.style = AvatarStyle.blob,
    this.selected = false,
    this.onTap,
    this.seed = 0,
  });

  @override
  State<AvatarFigure> createState() => _AvatarFigureState();
}

class _AvatarFigureState extends State<AvatarFigure> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _c.value = (widget.seed * 0.21) % 1.0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: u.scale,
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final dy = math.sin(_c.value * math.pi * 2) * 4;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (u.prayer != null) ...[
                _PrayerBubble(text: u.prayer!),
                const SizedBox(height: 4),
              ],
              _NameTag(u: u, selected: widget.selected),
              const SizedBox(height: 5),
              AvatarBody(color: u.color, color2: u.color2, style: widget.style, highlight: widget.selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  final AvatarUser u;
  final bool selected;
  const _NameTag({required this.u, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? u.color : const Color(0x990E0B1A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(0.14)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (u.live) ...[
            const PulseDot(color: AC.live, size: 5),
            const SizedBox(width: 4),
          ],
          Text(
            u.name,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF1A1030) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class AvatarBody extends StatelessWidget {
  final Color color;
  final Color color2;
  final AvatarStyle style;
  final bool highlight;
  final bool self;

  const AvatarBody({
    super.key,
    required this.color,
    required this.color2,
    this.style = AvatarStyle.blob,
    this.highlight = false,
    this.self = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 8,
            child: _GlowCircle(color: color, size: style == AvatarStyle.orb ? 46 : 54, strong: highlight),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              width: 42,
              height: 13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.6), Colors.transparent],
                  stops: const [0, 0.68],
                ),
              ),
            ),
          ),
          if (self)
            Positioned(bottom: -4, child: const _SelfRing()),
          ..._buildBody(),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    final headGrad = RadialGradient(center: const Alignment(-0.3, -0.45), colors: [color2, color]);
    if (style == AvatarStyle.orb) {
      return [
        Positioned(
          bottom: 14,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.32, -0.4),
                colors: [Colors.white, color2, color],
                stops: const [0, 0.3, 0.78],
              ),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.7), blurRadius: 20),
                const BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
      ];
    }
    final headSize = style == AvatarStyle.figure ? 17.0 : 20.0;
    final torsoW = style == AvatarStyle.figure ? 22.0 : 30.0;
    final torsoH = style == AvatarStyle.figure ? 34.0 : 32.0;
    return [
      Positioned(
        bottom: 8,
        child: Container(
          width: torsoW,
          height: torsoH,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color2, color]),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.elliptical(20, 26),
              topRight: Radius.elliptical(20, 26),
              bottomLeft: Radius.elliptical(16, 12),
              bottomRight: Radius.elliptical(16, 12),
            ),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
        ),
      ),
      Positioned(
        bottom: 8 + torsoH - 6,
        child: Container(
          width: headSize,
          height: headSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: headGrad,
            boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
        ),
      ),
    ];
  }
}

class _GlowCircle extends StatefulWidget {
  final Color color;
  final double size;
  final bool strong;
  const _GlowCircle({required this.color, this.size = 54, this.strong = false});

  @override
  State<_GlowCircle> createState() => _GlowCircleState();
}

class _GlowCircleState extends State<_GlowCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: widget.strong ? 0.9 : 0.7, end: 1.0).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [widget.color.withOpacity(0.6), Colors.transparent],
            stops: const [0, 0.64],
          ),
        ),
      ),
    );
  }
}

class _SelfRing extends StatefulWidget {
  const _SelfRing();

  @override
  State<_SelfRing> createState() => _SelfRingState();
}

class _SelfRingState extends State<_SelfRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(1.0, 0.42),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xE6FFDD96), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFFFFC86E).withOpacity(0.7), blurRadius: 14)],
          ),
        ),
      ),
    );
  }
}

class SelfAvatar extends StatefulWidget {
  final String nickname;
  final AvatarStyle style;
  final VoidCallback? onTap;
  final String? prayer;
  const SelfAvatar({super.key, this.nickname = '나', this.style = AvatarStyle.blob, this.onTap, this.prayer});

  @override
  State<SelfAvatar> createState() => _SelfAvatarState();
}

class _SelfAvatarState extends State<SelfAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, math.sin(_c.value * math.pi * 2) * 4), child: child),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.prayer != null) ...[
              _PrayerBubble(text: widget.prayer!),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF5DC), Color(0xFFFFCE7A)],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                widget.nickname,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF3A2406)),
              ),
            ),
            const SizedBox(height: 5),
            AvatarBody(
              color: const Color(0xFFFFB44D),
              color2: const Color(0xFFFFE9B8),
              style: widget.style,
              self: true,
            ),
          ],
        ),
      ),
    );
  }
}

class RoomPortal extends StatefulWidget {
  final String label;
  final String sub;
  final Color hue;
  final bool live;
  final VoidCallback onTap;
  const RoomPortal({super.key, required this.label, required this.sub, required this.hue, required this.onTap, this.live = false});

  @override
  State<RoomPortal> createState() => _RoomPortalState();
}

class _RoomPortalState extends State<RoomPortal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _down ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final glow = widget.live ? (0.5 + 0.3 * _c.value) : 0.5;
                return Container(
                  width: 58,
                  height: 74,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(29, 44),
                      topRight: Radius.elliptical(29, 44),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AC.mix(widget.hue, const Color(0x80140C24), 0.7), const Color(0xB30C0918)],
                    ),
                    border: Border.all(color: AC.mix(widget.hue, Colors.white, 0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: widget.hue.withOpacity(glow), blurRadius: widget.live ? 34 : 22)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: -22,
                        height: 66,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: RadialGradient(
                              center: Alignment.bottomCenter,
                              colors: [AC.mix(widget.hue, Colors.white, 0.4), Colors.transparent],
                              stops: const [0, 0.62],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.live) ...[
                const PulseDot(color: AC.live, size: 5),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0xB3000000), blurRadius: 6)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            widget.sub,
            style: const TextStyle(
              fontSize: 9.5,
              color: AC.muted,
              shadows: [Shadow(color: Color(0xB3000000), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

void showSelfProfileSheet(BuildContext context, String nickname) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66040208),
    isScrollControlled: true,
    builder: (ctx) => _SelfProfileSheet(nickname: nickname),
  );
}

class _SelfProfileSheet extends StatefulWidget {
  final String nickname;
  const _SelfProfileSheet({required this.nickname});

  @override
  State<_SelfProfileSheet> createState() => _SelfProfileSheetState();
}

class _SelfProfileSheetState extends State<_SelfProfileSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _prayerRepo = PrayerRepository();
  final _challengeRepo = ChallengeRepository();
  List<Map<String, dynamic>> _prayers = [];
  List<Map<String, dynamic>> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _prayerRepo.getMyPrayers(),
      _challengeRepo.getMyJoinedChallenges(),
    ]);
    if (mounted) {
      setState(() {
        _prayers = results[0];
        _challenges = results[1];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 60),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.45),
                      colors: [Color(0xFFFFE9B8), Color(0xFFFFB44D)],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.nickname,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                    child: const Icon(Icons.close, size: 15, color: AC.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AC.light.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AC.light.withOpacity(0.5)),
                ),
                labelColor: AC.light,
                unselectedLabelColor: AC.muted,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(3),
                tabs: const [Tab(text: '기도제목'), Tab(text: '챌린지')],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _buildPrayers(),
                        _buildChallenges(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayers() {
    if (_prayers.isEmpty) {
      return const Center(
        child: Text('기도제목이 없어요', style: TextStyle(color: AC.muted, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _prayers.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          _prayers[i]['content'] as String,
          style: const TextStyle(
              fontSize: 13.5, color: Color(0xFFE9E4FF), height: 1.5),
        ),
      ),
    );
  }

  Widget _buildChallenges() {
    if (_challenges.isEmpty) {
      return const Center(
        child: Text('참여 중인 챌린지가 없어요',
            style: TextStyle(color: AC.muted, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _challenges.length,
      itemBuilder: (_, i) {
        final c = _challenges[i];
        final total = (c['total_days'] as int?) ?? 21;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(c['title'] as String,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFFE9E4FF))),
              ),
              Text('$total일',
                  style: const TextStyle(fontSize: 11, color: AC.muted)),
            ],
          ),
        );
      },
    );
  }
}

void showProfileSheet(BuildContext context, AvatarUser u, void Function(AvatarUser, String) onGreet) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66040208),
    isScrollControlled: true,
    builder: (ctx) => _ProfileSheet(user: u, onGreet: onGreet),
  );
}

class _ProfileSheet extends StatefulWidget {
  final AvatarUser user;
  final void Function(AvatarUser, String) onGreet;
  const _ProfileSheet({required this.user, required this.onGreet});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 60),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.45),
                      colors: [u.color2, u.color],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(u.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          if (u.live) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(color: AC.live, borderRadius: BorderRadius.circular(5)),
                              child: const Text('LIVE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(u.role, style: const TextStyle(fontSize: 12, color: AC.muted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                    child: const Icon(Icons.close, size: 15, color: AC.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 탭바
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AC.light.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AC.light.withOpacity(0.5)),
                ),
                labelColor: AC.light,
                unselectedLabelColor: AC.muted,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(3),
                tabs: const [Tab(text: '기도제목'), Tab(text: '챌린지')],
              ),
            ),
            const SizedBox(height: 10),
            // 탭 콘텐츠
            SizedBox(
              height: 160,
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildPrayers(u),
                  _buildChallenges(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 인사하기
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onGreet(u, '');
              },
              child: Container(
                width: double.infinity,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                  ),
                  boxShadow: [BoxShadow(color: AC.light.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: const Text('인사하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1030))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayers(AvatarUser u) {
    // 실시간 연동(6단계) 전까지 status를 기도제목 샘플로 표시
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  u.status,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFFE9E4FF), height: 1.5),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('멀티플레이 오픈 후 담기 가능해요'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AC.glass1.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AC.glass1.withOpacity(0.5)),
                  ),
                  child: const Text('담기', style: TextStyle(fontSize: 11, color: AC.glass1, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallenges() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_rounded, size: 28, color: AC.muted),
          SizedBox(height: 8),
          Text('멀티플레이 오픈 후 연동돼요', style: TextStyle(color: AC.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PrayerBubble extends StatelessWidget {
  final String text;
  const _PrayerBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xDD1A1230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFFE9E4FF),
              height: 1.45,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _BubbleTailPainter(),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xDD1A1230)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
