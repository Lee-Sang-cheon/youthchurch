import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../home/data/prayer_repository.dart';
import '../data/church_presence_service.dart';
import 'widgets/room_nav.dart';
import '../domain/avatar_user.dart';
import 'widgets/avatar_widgets.dart';

class PrayerRoomPage extends StatefulWidget {
  const PrayerRoomPage({super.key});

  @override
  State<PrayerRoomPage> createState() => _PrayerRoomPageState();
}

class _PrayerRoomPageState extends State<PrayerRoomPage> {
  double _selfX = 50, _selfY = 72;
  List<AvatarUser> _onlineUsers = [];
  List<Map<String, dynamic>> _prayers = [];
  bool _loading = true;

  final _presence = ChurchPresenceService();
  final _prayerRepo = PrayerRepository();

  String get _myNickname {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['nickname'] as String? ?? '나';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _prayerRepo.getMyPrayers(),
      _prayerRepo.getSavedPrayers(),
    ]);

    final myPrayers = results[0].map((p) => {...p, '_source': 'mine'}).toList();
    final savedPrayers = <Map<String, dynamic>>[];
    for (final row in results[1]) {
      final pr = row['prayer_requests'];
      if (pr is Map<String, dynamic>) {
        savedPrayers.add({...pr, '_source': 'saved'});
      }
    }

    if (mounted) {
      setState(() {
        _prayers = [...myPrayers, ...savedPrayers];
        _loading = false;
      });
    }

    await _presence.join(
      nickname: _myNickname,
      x: _selfX,
      y: _selfY,
      room: 'prayer_room',
    );
    _presence.usersStream.listen((users) {
      if (mounted) setState(() => _onlineUsers = users);
    });
  }

  void _onTapBackground(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx / constraints.maxWidth * 100;
    final y = details.localPosition.dy / constraints.maxHeight * 100;
    if (y < 44 || y > 88) return;
    setState(() {
      _selfX = x.clamp(8, 92);
      _selfY = y.clamp(44, 88);
    });
    _presence.updatePosition(_selfX, _selfY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      bottomNavigationBar: const RoomNavBar(current: RoomType.prayer),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _onTapBackground(d, constraints),
              child: Stack(
                children: [
                  const Positioned.fill(child: _PrayerRoomBg()),
                  // 게시판 (상단 벽면 영역)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: constraints.maxHeight * 0.42,
                    child: _buildBulletinBoard(constraints),
                  ),
                  // 다른 유저
                  for (var i = 0; i < _onlineUsers.length; i++)
                    _buildUserAvatar(_onlineUsers[i], constraints, i),
                  // 내 아바타
                  _buildSelfAvatar(constraints),
                  // 힌트
                  Positioned(
                    left: 0, right: 0,
                    bottom: constraints.maxHeight * 0.13,
                    child: const IgnorePointer(
                      child: Text(
                        '카드를 탭해 함께 기도해요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AC.muted,
                          shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          Positioned(
            left: 14, right: 14, bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Glass(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded, size: 14, color: AC.glass1),
                      const SizedBox(width: 8),
                      Text(
                        '지금 ${_onlineUsers.length + 1}명이 함께 기도 중',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinBoard(BoxConstraints constraints) {
    final topPad = MediaQuery.of(context).padding.top + constraints.maxHeight * 0.09;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPad),
        Padding(
          padding: const EdgeInsets.only(left: 18, bottom: 10),
          child: Text(
            '기도제목 ${_prayers.isEmpty ? '' : '(${_prayers.length})'}',
            style: const TextStyle(fontSize: 11, color: AC.muted, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _prayers.isEmpty
                  ? const Center(
                      child: Text('기도제목을 추가해보세요',
                          style: TextStyle(color: AC.muted, fontSize: 13)),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _prayers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _PrayerCard(
                        prayer: _prayers[i],
                        repo: _prayerRepo,
                        onTap: () => _showPrayerDetail(_prayers[i]),
                      ),
                    ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildUserAvatar(AvatarUser user, BoxConstraints c, int index) {
    final x = user.x / 100 * c.maxWidth;
    final y = user.y / 100 * c.maxHeight;
    return Positioned(
      left: x - 30,
      top: y - 40,
      child: AvatarFigure(user: user, seed: index),
    );
  }

  Widget _buildSelfAvatar(BoxConstraints c) {
    final x = _selfX / 100 * c.maxWidth;
    final y = _selfY / 100 * c.maxHeight;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: x - 30,
      top: y - 80,
      child: SelfAvatar(nickname: _myNickname),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Glass(
                radius: 999,
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Glass(
              radius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.self_improvement_rounded, size: 14, color: AC.glass1),
                  const SizedBox(width: 6),
                  const Text('기도실',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 13, color: Colors.white24),
                  const SizedBox(width: 8),
                  Text(
                    '${_onlineUsers.length + 1}명',
                    style: const TextStyle(fontSize: 12, color: AC.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrayerDetail(Map<String, dynamic> prayer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PrayerDetailSheet(prayer: prayer, repo: _prayerRepo),
    );
  }
}

// ─── 기도제목 카드 ───────────────────────────────────────────

class _PrayerCard extends StatefulWidget {
  final Map<String, dynamic> prayer;
  final PrayerRepository repo;
  final VoidCallback onTap;
  const _PrayerCard({required this.prayer, required this.repo, required this.onTap});

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard> {
  int _prayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final count = await widget.repo.getPrayCount(widget.prayer['id'] as String);
    if (mounted) setState(() => _prayCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.prayer['_source'] == 'mine';
    final content = widget.prayer['content'] as String? ?? '';
    final accent = isMine ? AC.light : AC.glass1;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xCC14102A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 14)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isMine ? '내 기도' : '담아둔',
                style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE9E4FF), height: 1.5),
              ),
            ),
            if (_prayCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 10, color: AC.glass1),
                  const SizedBox(width: 3),
                  Text('$_prayCount명',
                      style: const TextStyle(fontSize: 10, color: AC.muted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 기도제목 상세 시트 ──────────────────────────────────────

class _PrayerDetailSheet extends StatefulWidget {
  final Map<String, dynamic> prayer;
  final PrayerRepository repo;
  const _PrayerDetailSheet({required this.prayer, required this.repo});

  @override
  State<_PrayerDetailSheet> createState() => _PrayerDetailSheetState();
}

class _PrayerDetailSheetState extends State<_PrayerDetailSheet> {
  bool _isPraying = false;
  int _prayCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.prayer['id'] as String;
    final results = await Future.wait([
      widget.repo.isAlreadyPraying(id),
      widget.repo.getPrayCount(id),
    ]);
    if (mounted) {
      setState(() {
        _isPraying = results[0] as bool;
        _prayCount = results[1] as int;
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    final id = widget.prayer['id'] as String;
    if (_isPraying) {
      await widget.repo.unprayForPrayer(id);
      if (mounted) setState(() { _isPraying = false; _prayCount--; });
    } else {
      await widget.repo.prayForPrayer(id);
      if (mounted) setState(() { _isPraying = true; _prayCount++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.prayer['_source'] == 'mine';
    final content = widget.prayer['content'] as String? ?? '';
    final accent = isMine ? AC.light : AC.glass1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isMine ? '내 기도제목' : '담아둔 기도제목',
                    style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                    child: const Icon(Icons.close, size: 14, color: AC.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(content,
                style: const TextStyle(fontSize: 15, color: Color(0xFFE9E4FF), height: 1.6)),
            const SizedBox(height: 20),
            if (_prayCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 13, color: AC.glass1),
                    const SizedBox(width: 5),
                    Text('지금 $_prayCount명이 함께 기도 중',
                        style: const TextStyle(fontSize: 12, color: AC.muted)),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _loading ? null : _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _isPraying
                      ? LinearGradient(colors: [
                          AC.glass1.withOpacity(0.25),
                          AC.glass1.withOpacity(0.1),
                        ])
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                        ),
                  border: _isPraying ? Border.all(color: AC.glass1.withOpacity(0.5)) : null,
                  boxShadow: _isPraying
                      ? []
                      : [BoxShadow(color: AC.light.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPraying ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: _isPraying ? AC.glass1 : const Color(0xFF1A1030),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPraying ? '기도하는 중' : '함께 기도하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _isPraying ? AC.glass1 : const Color(0xFF1A1030),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 배경 ────────────────────────────────────────────────────

class _PrayerRoomBg extends StatelessWidget {
  const _PrayerRoomBg();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.5),
                  radius: 1.1,
                  colors: [Color(0xFF2A1505), Color(0xFF120D20), Color(0xFF06030F)],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
          ),
          // 바닥
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: c.maxHeight * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [const Color(0xFF1A0D03).withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),
          // 촛불 글로우
          Positioned(
            bottom: c.maxHeight * 0.10,
            left: c.maxWidth / 2 - 70,
            child: const _CandleGlow(),
          ),
          // 벽 (상단 게시판 영역)
          Positioned(
            top: 0, left: 0, right: 0,
            height: c.maxHeight * 0.44,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1C1008), Colors.transparent],
                ),
              ),
            ),
          ),
          // 비네트
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [Colors.transparent, Color(0xDD04020A)],
                    stops: [0.38, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandleGlow extends StatefulWidget {
  const _CandleGlow();

  @override
  State<_CandleGlow> createState() => _CandleGlowState();
}

class _CandleGlowState extends State<_CandleGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.65).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 140,
        height: 140,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x88FFAA44), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
