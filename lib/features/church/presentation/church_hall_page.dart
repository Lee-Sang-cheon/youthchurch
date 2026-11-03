import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../home/data/prayer_repository.dart';
import '../../auth/presentation/church_setup_page.dart';
import '../data/church_presence_service.dart';
import '../data/notification_repository.dart';
import 'prayer_room_page.dart';
import 'worship_hall_page.dart';
import 'small_group_room_page.dart';
import 'album_page.dart';
import 'schedule_page.dart';
import 'members_page.dart';
import 'my_page.dart';
import 'playground_page.dart';
import '../domain/avatar_user.dart';
import 'widgets/avatar_widgets.dart';
import 'church_webview_scene.dart';

class ChurchHallPage extends StatefulWidget {
  const ChurchHallPage({super.key});

  @override
  State<ChurchHallPage> createState() => _ChurchHallPageState();
}

class _ChurchHallPageState extends State<ChurchHallPage> {
  int _navIndex = 0;
  String? _myLatestPrayer;
  List<AvatarUser> _onlineUsers = [];
  int _unreadCount = 0;
  final _presence = ChurchPresenceService();
  final _notifRepo = NotificationRepository();
  final _sceneKey = GlobalKey<ChurchWebViewSceneState>();

  @override
  void initState() {
    super.initState();
    _loadLatestPrayer();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await _notifRepo.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
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
      x: 50,
      y: 50,
    );
    _presence.usersStream.listen((users) {
      if (mounted) {
        setState(() => _onlineUsers = users);
        _sceneKey.currentState?.updateOtherUsers(users);
      }
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

  void _onGreet(AvatarUser user, String emoji) {
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
      backgroundColor: const Color(0xFF080512),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Three.js WebView 3D 씬
          ChurchWebViewScene(
            key: _sceneKey,
            playerName: _myNickname,
            playerColor: const Color(0xFFFFB44D),
            onMove: (x, y) => _presence.updatePosition(x, y),
          ),
          // 포탈 오버레이
          Positioned.fill(child: _buildPortalOverlay()),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // 포탈 버튼 오버레이 (화면 4방향 가장자리에 배치)
  Widget _buildPortalOverlay() {
    return SafeArea(
      child: Stack(
        children: [
          // 기도실 - 좌측 중앙
          Positioned(
            left: 12,
            top: 0,
            bottom: 80,
            child: Center(
              child: _PortalButton(
                label: '기도실',
                hue: AC.glass1,
                icon: Icons.self_improvement_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerRoomPage())),
              ),
            ),
          ),
          // 예배당 - 우측 중앙
          Positioned(
            right: 12,
            top: 0,
            bottom: 80,
            child: Center(
              child: _PortalButton(
                label: '예배당',
                hue: AC.light,
                icon: Icons.music_note_rounded,
                onTap: _enterWorshipHall,
              ),
            ),
          ),
          // 놀이터 - 상단 좌측
          Positioned(
            left: 72,
            top: 70,
            child: _PortalButton(
              label: '놀이터',
              hue: const Color(0xFF4CAF50),
              icon: Icons.sports_esports_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaygroundPage())),
            ),
          ),
          // 소그룹 - 상단 우측
          Positioned(
            right: 72,
            top: 70,
            child: _PortalButton(
              label: '소그룹',
              hue: AC.glass2,
              icon: Icons.groups_rounded,
              onTap: _showMySmallGroups,
            ),
          ),
          // 이동 힌트
          const Positioned(
            left: 0, right: 0, bottom: 90,
            child: IgnorePointer(
              child: Text(
                '바닥 타일을 탭해서 이동해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AC.muted,
                  shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _enterWorshipHall() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorshipHallPage()));
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _NotificationsPageMain(notifRepo: _notifRepo),
                  ),
                ).then((_) async {
                  await _notifRepo.markAllAsRead();
                  _loadUnreadCount();
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Glass(
                    radius: 999,
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4D),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
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


class _PortalButton extends StatefulWidget {
  final String label;
  final Color hue;
  final IconData icon;
  final VoidCallback onTap;
  const _PortalButton({required this.label, required this.hue, required this.icon, required this.onTap});

  @override
  State<_PortalButton> createState() => _PortalButtonState();
}

class _PortalButtonState extends State<_PortalButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final p = _pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 외부 글로우
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.hue.withOpacity(0.35 + 0.2 * p),
                          blurRadius: 24 + 12 * p,
                          spreadRadius: 2 + 4 * p,
                        ),
                        BoxShadow(
                          color: widget.hue.withOpacity(0.15 + 0.1 * p),
                          blurRadius: 48 + 16 * p,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // 오브 본체
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.25, -0.3),
                        radius: 1.1,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          widget.hue,
                          widget.hue.withOpacity(0.55),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
                  ),
                  // 하이라이트 반짝이
                  Positioned(
                    top: 10,
                    left: 15,
                    child: Container(
                      width: 13,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withOpacity(0.55 + 0.2 * p),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 7),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(color: widget.hue.withOpacity(0.9), blurRadius: 10),
                Shadow(color: widget.hue.withOpacity(0.4), blurRadius: 24),
              ],
            ),
          ),
        ],
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
    try {
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
    } catch (_) {
      if (mounted) setState(() { _groups = []; _loading = false; });
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
            else ...[
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
              const SizedBox(height: 4),
              Builder(builder: (ctx) => GestureDetector(
                onTap: () => _showCreateGroupSheet(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: AC.muted, size: 16),
                      SizedBox(width: 6),
                      Text('소그룹 추가하기', style: TextStyle(color: AC.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 알림 페이지 ──────────────────────────────────────────────────────────────
class _NotificationsPageMain extends StatefulWidget {
  final NotificationRepository notifRepo;
  const _NotificationsPageMain({required this.notifRepo});

  @override
  State<_NotificationsPageMain> createState() => _NotificationsPageMainState();
}

class _NotificationsPageMainState extends State<_NotificationsPageMain> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.notifRepo.getNotifications();
      if (mounted) setState(() { _notifs = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _notifs = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF120D20), Color(0xFF06030F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Glass(
                        radius: 999,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('알림',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_notifs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: AC.muted),
                        SizedBox(height: 12),
                        Text('알림이 없습니다', style: TextStyle(color: AC.muted, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final notif = _notifs[i];
                      final message = notif['message'] as String? ?? '';
                      final isRead = notif['is_read'] as bool? ?? false;
                      final type = notif['type'] as String? ?? '';
                      final isInvite = type == 'partner_invite';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? const Color(0xCC14102A) : const Color(0xFF1E1840),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isRead ? Colors.white12 : AC.light.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isInvite ? Icons.people_rounded : Icons.favorite_rounded,
                              size: 16,
                              color: isInvite ? const Color(0xFFB39DDB) : AC.glass1,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(message,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFE9E4FF), height: 1.5)),
                            ),
                            if (!isRead)
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: Color(0xFFFF4D4D), shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
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
