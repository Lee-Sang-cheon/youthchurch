import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../home/data/prayer_repository.dart';
import '../../auth/presentation/church_setup_page.dart';
import '../data/church_presence_service.dart';
import 'prayer_room_page.dart';
import 'worship_hall_page.dart';
import 'small_group_room_page.dart';
import 'album_page.dart';
import 'schedule_page.dart';
import 'members_page.dart';
import 'my_page.dart';
import '../domain/avatar_user.dart';
import 'widgets/church_scene_bg.dart';
import 'widgets/avatar_widgets.dart';

class ChurchHallPage extends StatefulWidget {
  const ChurchHallPage({super.key});

  @override
  State<ChurchHallPage> createState() => _ChurchHallPageState();
}

class _ChurchHallPageState extends State<ChurchHallPage> {
  int _navIndex = 0;
  int? _selectedUserId;
  String? _myLatestPrayer;
  List<AvatarUser> _onlineUsers = [];
  final _presence = ChurchPresenceService();

  // 내 아바타 위치 (화면 % 기준, 0~100)
  double _selfX = 50;
  double _selfY = 74;

  @override
  void initState() {
    super.initState();
    _loadLatestPrayer();
  }

  Future<void> _loadLatestPrayer() async {
    final prayers = await PrayerRepository().getMyPrayers();
    if (mounted && prayers.isNotEmpty) {
      setState(() => _myLatestPrayer = prayers.first['content'] as String?);
    }
    // 기도제목 로드 후 presence 참여
    await _presence.join(
      nickname: _myNickname,
      prayer: _myLatestPrayer,
      x: _selfX,
      y: _selfY,
    );
    _presence.usersStream.listen((users) {
      if (mounted) setState(() => _onlineUsers = users);
    });
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  String get _myNickname {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['nickname'] as String? ?? '나';
  }

  void _onTapBackground(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx / constraints.maxWidth * 100;
    final y = details.localPosition.dy / constraints.maxHeight * 100;
    // 바닥 영역만 이동 허용
    if (y < 35 || y > 88) return;
    setState(() {
      _selfX = x.clamp(8, 92);
      _selfY = y.clamp(35, 88);
      _selectedUserId = null;
    });
    _presence.updatePosition(_selfX, _selfY); // throttled 500ms
  }

  void _onGreet(AvatarUser user, String emoji) {
    // 인사 리액션 표시 (추후 실시간 연동)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji ${user.name}에게 인사했어요!'),
        backgroundColor: AC.stone,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bgBot,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 + 씬 (non-positioned → StackFit.expand으로 꽉 채움)
          _buildScene(),
          // 상단 바
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          // 바텀 네비게이션
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildScene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => _onTapBackground(details, constraints),
          child: Stack(
            children: [
              // 교회 배경
              const Positioned.fill(child: ChurchScene()),

              // 포탈 (문)
              Positioned.fill(child: _buildPortals(constraints)),

              // 다른 유저 아바타 (실시간)
              for (var i = 0; i < _onlineUsers.length; i++)
                _buildUserAvatar(_onlineUsers[i], constraints, i),

              // 내 아바타
              _buildSelfAvatar(constraints),

              // 힌트 텍스트
              Positioned(
                left: 0,
                right: 0,
                bottom: constraints.maxHeight * 0.12,
                child: const IgnorePointer(
                  child: Text(
                    '바닥을 탭하면 이동해요 · 아바타를 탭해 인사하기',
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
        );
      },
    );
  }

  Widget _buildUserAvatar(AvatarUser user, BoxConstraints c, int index) {
    final x = user.x / 100 * c.maxWidth;
    final y = user.y / 100 * c.maxHeight;
    return Positioned(
      left: x - 30,
      top: y - 40,
      child: AvatarFigure(
        user: user,
        seed: index,
        selected: _selectedUserId == user.id,
        onTap: () {
          setState(() => _selectedUserId = user.id);
          showProfileSheet(context, user, _onGreet);
        },
      ),
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
      child: SelfAvatar(
        nickname: _myNickname,
        prayer: _myLatestPrayer,
        onTap: () => showSelfProfileSheet(context, _myNickname),
      ),
    );
  }

  Widget _buildPortals(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final portals = [
      _PortalData(label: '기도실', icon: Icons.arrow_back_ios_new_rounded, hue: AC.glass1, xPct: 0.12, yPct: 0.50, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerRoomPage()))),
      _PortalData(label: '예배당', icon: Icons.arrow_forward_ios_rounded, hue: AC.light, xPct: 0.88, yPct: 0.50, onTap: () => _enterWorshipHall()),
      _PortalData(label: '소그룹', icon: Icons.keyboard_arrow_down_rounded, hue: AC.glass2, xPct: 0.50, yPct: 0.20, onTap: () => _showMySmallGroups()),
    ];
    return Stack(
      children: [
        for (final p in portals)
          Positioned(
            left: p.xPct * w - 36,
            bottom: p.yPct * h,
            child: _RoomButton(
              label: p.label,
              icon: p.icon,
              hue: p.hue,
              onTap: p.onTap ?? () => _showComingSoon(p.label),
            ),
          ),
      ],
    );
  }

  void _enterWorshipHall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WorshipEntrySheet(
        onEnter: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WorshipHallPage()));
        },
      ),
    );
  }

  void _showMySmallGroups() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MySmallGroupSheet(
        onEnter: (id, name) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => SmallGroupRoomPage(cellGroupId: id, groupName: name)));
        },
      ),
    );
  }

  void _showComingSoon(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
        child: Glass(
          radius: 24,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text('곧 오픈 예정이에요!', style: TextStyle(fontSize: 14, color: AC.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Row(
          children: [
            Glass(
              radius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulseDot(color: AC.online, size: 8),
                  const SizedBox(width: 8),
                  const Text('청년부 라운지', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 13, color: Colors.white24),
                  const SizedBox(width: 8),
                  Text(
                    '접속 ${_onlineUsers.length + 1}',
                    style: const TextStyle(fontSize: 12, color: AC.muted),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const ChurchInviteSheet(),
              ),
              child: Glass(
                radius: 999,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_rounded, color: AC.light, size: 16),
                    SizedBox(width: 6),
                    Text('초대', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AC.light)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (_NavItem(icon: Icons.photo_library_rounded, label: '앨범')),
      (_NavItem(icon: Icons.calendar_month_rounded, label: '일정')),
      (_NavItem(icon: Icons.people_rounded, label: '구성원')),
      (_NavItem(icon: Icons.manage_accounts_rounded, label: '마이페이지')),
    ];

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC0C0918),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(child: _buildNavItem(items[i], i)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index) {
    final selected = _navIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumPage()));
          return;
        }
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulePage()));
          return;
        }
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersPage()));
          return;
        }
        if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPage()));
          return;
        }
        setState(() => _navIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 22,
            color: selected ? AC.light : Colors.white.withOpacity(0.35),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AC.light : Colors.white.withOpacity(0.35),
            ),
          ),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AC.light),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _PortalData {
  final String label;
  final IconData icon;
  final Color hue;
  final double xPct, yPct;
  final VoidCallback? onTap;
  const _PortalData({
    required this.label,
    required this.icon,
    required this.hue,
    required this.xPct,
    required this.yPct,
    this.onTap,
  });
}

class _RoomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color hue;
  final VoidCallback onTap;
  const _RoomButton({required this.label, required this.icon, required this.hue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xBB0E0B1A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: hue.withOpacity(0.5), width: 1.2),
          boxShadow: [BoxShadow(color: hue.withOpacity(0.3), blurRadius: 14)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: hue),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hue),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 예배당 QR 스캔 입장 ──────────────────────────────────────────────────────
class _WorshipEntrySheet extends StatefulWidget {
  final VoidCallback onEnter;
  const _WorshipEntrySheet({required this.onEnter});

  @override
  State<_WorshipEntrySheet> createState() => _WorshipEntrySheetState();
}

class _WorshipEntrySheetState extends State<_WorshipEntrySheet> {
  final _client = Supabase.instance.client;
  final _ctrl = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty || _verifying) return;
    setState(() => _verifying = true);
    try {
      final uid = _client.auth.currentUser?.id;
      final user = await _client.from('users').select('church_id').eq('id', uid!).maybeSingle();
      final churchId = user?['church_id'] as String?;
      if (churchId == null) { _showError('교회 정보가 없어요'); return; }
      final worship = await _client
          .from('weekly_worship')
          .select('entry_code')
          .eq('church_id', churchId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();
      final correct = (worship?['entry_code'] as String?)?.toUpperCase();
      if (correct == null || correct != code.toUpperCase()) {
        _showError('입장 코드가 올바르지 않아요');
        return;
      }
      widget.onEnter();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[400], duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.church_rounded, color: AC.light, size: 32),
            const SizedBox(height: 8),
            const Text('예배당 입장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('입장 코드를 입력해주세요', style: TextStyle(fontSize: 13, color: AC.muted)),
            const SizedBox(height: 20),
            Glass(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 4),
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '코드 6자리',
                  hintStyle: TextStyle(color: AC.muted, fontSize: 16, letterSpacing: 2),
                  border: InputBorder.none,
                  counterText: '',
                ),
                onSubmitted: (_) => _verify(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AC.light,
                  foregroundColor: const Color(0xFF1A1030),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _verifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('입장하기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 내 소그룹 리스트 시트 ────────────────────────────────────────────────────
class _MySmallGroupSheet extends StatefulWidget {
  final void Function(String id, String name) onEnter;
  const _MySmallGroupSheet({required this.onEnter});

  @override
  State<_MySmallGroupSheet> createState() => _MySmallGroupSheetState();
}

class _MySmallGroupSheetState extends State<_MySmallGroupSheet> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  void _showCreateGroupSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(onCreated: _load),
    );
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) { if (mounted) setState(() => _loading = false); return; }
    final memberships = await _client
        .from('cell_group_members')
        .select('cell_group_id, cell_groups(id, name)')
        .eq('user_id', uid);
    if (mounted) {
      setState(() {
        _groups = memberships
            .map((m) => m['cell_groups'] as Map<String, dynamic>? ?? {})
            .where((g) => g.isNotEmpty)
            .toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('소그룹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            if (_loading)
              const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
            else if (_groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.group_off_rounded, color: AC.muted, size: 40),
                    const SizedBox(height: 10),
                    const Text('소속된 소그룹이 없습니다', style: TextStyle(color: AC.muted, fontSize: 14)),
                    const SizedBox(height: 20),
                    Builder(builder: (ctx) => GestureDetector(
                      onTap: () => _showCreateGroupSheet(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AC.glass2.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AC.glass2.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: AC.glass2, size: 18),
                            SizedBox(width: 8),
                            Text('소그룹 만들기', style: TextStyle(color: AC.glass2, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              )
            else
              ...(_groups.map((g) => GestureDetector(
                onTap: () => widget.onEnter(g['id'] as String, g['name'] as String? ?? ''),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AC.glass2.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AC.glass2.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, color: AC.glass2, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g['name'] as String? ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AC.muted, size: 14),
                    ],
                  ),
                ),
              ))),
          ],
        ),
      ),
    );
  }
}

// ── 소그룹 만들기 (멤버 선택 포함) ──────────────────────────────────────────
class _CreateGroupSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateGroupSheet({required this.onCreated});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _members = [];
  final Set<String> _selected = {};
  bool _loadingMembers = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _loadMembers() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final user = await _client.from('users').select('church_id').eq('id', uid).maybeSingle();
    final churchId = user?['church_id'] as String?;
    if (churchId == null) { if (mounted) setState(() => _loadingMembers = false); return; }
    final members = await _client
        .from('users')
        .select('id, nickname')
        .eq('church_id', churchId)
        .neq('id', uid)
        .order('nickname');
    if (mounted) setState(() {
      _members = List<Map<String, dynamic>>.from(members);
      _loadingMembers = false;
    });
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = _client.auth.currentUser?.id!;
      final user = await _client.from('users').select('church_id').eq('id', uid!).maybeSingle();
      final churchId = user?['church_id'] as String?;
      if (churchId == null) return;
      final group = await _client
          .from('cell_groups')
          .insert({'name': name, 'church_id': churchId})
          .select()
          .single();
      final groupId = group['id'] as String;
      // 나 + 선택된 멤버 추가
      final toAdd = [uid, ..._selected];
      await _client.from('cell_group_members').insert(
        toAdd.map((id) => {'cell_group_id': groupId, 'user_id': id}).toList(),
      );
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red[400]),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('소그룹 만들기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            Glass(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '소그룹 이름 (예: 1청년부 1셀)',
                  hintStyle: TextStyle(color: AC.muted),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('멤버 초대', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.muted)),
            const SizedBox(height: 8),
            if (_loadingMembers)
              const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
            else if (_members.isEmpty)
              const Text('교회에 다른 멤버가 없어요', style: TextStyle(color: AC.muted, fontSize: 13))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  itemBuilder: (_, i) {
                    final m = _members[i];
                    final id = m['id'] as String;
                    final nickname = m['nickname'] as String? ?? '';
                    final selected = _selected.contains(id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) _selected.remove(id); else _selected.add(id);
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AC.glass2.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AC.glass2.withOpacity(0.6) : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AC.light.withOpacity(0.15),
                              ),
                              child: Center(
                                child: Text(
                                  nickname.isNotEmpty ? nickname[0] : '?',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.light),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(nickname, style: const TextStyle(color: Colors.white, fontSize: 14))),
                            if (selected) const Icon(Icons.check_circle_rounded, color: AC.glass2, size: 18)
                            else const Icon(Icons.circle_outlined, color: AC.muted, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AC.glass2,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _selected.isEmpty ? '소그룹 만들기' : '${_selected.length + 1}명으로 만들기',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
