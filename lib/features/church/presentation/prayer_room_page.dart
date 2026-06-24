import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../home/data/prayer_repository.dart';
import '../data/church_presence_service.dart';
import '../data/partner_repository.dart';
import '../data/notification_repository.dart';
import '../domain/avatar_user.dart';
import 'widgets/avatar_widgets.dart';
import 'my_page.dart';

class PrayerRoomPage extends StatefulWidget {
  const PrayerRoomPage({super.key});

  @override
  State<PrayerRoomPage> createState() => _PrayerRoomPageState();
}

class _PrayerRoomPageState extends State<PrayerRoomPage> {
  double _selfX = 50, _selfY = 65;
  List<AvatarUser> _onlineUsers = [];
  List<Map<String, dynamic>> _leftPrayers = [];
  int _unreadCount = 0;

  final _presence = ChurchPresenceService();
  final _prayerRepo = PrayerRepository();
  final _notifRepo = NotificationRepository();
  final _partnerRepo = PartnerRepository();

  String get _myNickname {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['nickname'] as String? ?? '나';
  }

  @override
  void initState() {
    super.initState();
    _initPresence();
    _loadLeftPrayers();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  Future<void> _initPresence() async {
    await _presence.join(nickname: _myNickname, x: _selfX, y: _selfY, room: 'prayer_room');
    _presence.usersStream.listen((users) {
      if (mounted) setState(() => _onlineUsers = users);
    });
  }

  Future<void> _loadLeftPrayers() async {
    final prayers = await _prayerRepo.getLeftPrayers();
    if (mounted) setState(() => _leftPrayers = prayers);
  }

  Future<void> _loadUnreadCount() async {
    final count = await _notifRepo.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  void _onTapBackground(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx / constraints.maxWidth * 100;
    final y = details.localPosition.dy / constraints.maxHeight * 100;
    if (y < 15 || y > 88) return;
    setState(() {
      _selfX = x.clamp(8, 92);
      _selfY = y.clamp(15, 88);
    });
    _presence.updatePosition(_selfX, _selfY);
  }

  void _showWrite() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WriteSheet(
        repo: _prayerRepo,
        partnerRepo: _partnerRepo,
        notifRepo: _notifRepo,
        myNickname: _myNickname,
      ),
    );
  }

  void _showPrayList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PrayListSheet(repo: _prayerRepo, myNickname: _myNickname),
    ).then((_) => _loadLeftPrayers());
  }

  void _showRanking() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RankingSheet(repo: _prayerRepo),
    );
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotificationsPage(
          notifRepo: _notifRepo,
          partnerRepo: _partnerRepo,
        ),
      ),
    ).then((_) async {
      await _notifRepo.markAllAsRead();
      _loadUnreadCount();
    });
  }

  void _goMyPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _onTapBackground(d, constraints),
              child: Stack(
                children: [
                  const Positioned.fill(child: _PrayerRoomBg()),
                  for (final prayer in _leftPrayers)
                    _EnvelopeWidget(
                      prayer: prayer,
                      repo: _prayerRepo,
                      constraints: constraints,
                      onSaved: _loadLeftPrayers,
                    ),
                  for (var i = 0; i < _onlineUsers.length; i++)
                    _buildUserAvatar(_onlineUsers[i], constraints, i),
                  _buildSelfAvatar(constraints),
                ],
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AvatarUser user, BoxConstraints c, int index) {
    final x = user.x / 100 * c.maxWidth;
    final y = user.y / 100 * c.maxHeight;
    return Positioned(
      left: x - 30, top: y - 40,
      child: AvatarFigure(user: user, seed: index),
    );
  }

  Widget _buildSelfAvatar(BoxConstraints c) {
    final x = _selfX / 100 * c.maxWidth;
    final y = _selfY / 100 * c.maxHeight;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: x - 30, top: y - 80,
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
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 13, color: Colors.white24),
                  const SizedBox(width: 8),
                  Text('${_onlineUsers.length + 1}명',
                      style: const TextStyle(fontSize: 12, color: AC.muted)),
                ],
              ),
            ),
            const Spacer(),
            // 알림 종
            GestureDetector(
              onTap: _showNotifications,
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
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xEE0E0A1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.edit_rounded, label: '작성', onTap: _showWrite),
            _NavItem(icon: Icons.favorite_rounded, label: '기도하기', onTap: _showPrayList),
            _NavItem(icon: Icons.emoji_events_rounded, label: '순위', onTap: _showRanking),
            _NavItem(icon: Icons.person_rounded, label: '마이페이지', onTap: _goMyPage),
          ],
        ),
      ),
    );
  }
}

// ─── 네비 아이템 ─────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AC.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── 작성 시트 ───────────────────────────────────────────────

class _WriteSheet extends StatefulWidget {
  final PrayerRepository repo;
  final PartnerRepository partnerRepo;
  final NotificationRepository notifRepo;
  final String myNickname;
  const _WriteSheet({
    required this.repo,
    required this.partnerRepo,
    required this.notifRepo,
    required this.myNickname,
  });

  @override
  State<_WriteSheet> createState() => _WriteSheetState();
}

class _WriteSheetState extends State<_WriteSheet> {
  final _controller = TextEditingController();
  String _visibility = 'public';
  bool _loading = false;
  List<Map<String, dynamic>> _partnerGroups = [];
  String? _selectedGroupId;
  bool _loadingGroups = false;

  static const _groups = [
    ('전체', 'public'),
    ('나만', 'private'),
    ('목장', 'cell'),
    ('파트너', 'partner'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerGroups() async {
    setState(() => _loadingGroups = true);
    try {
      final groups = await widget.partnerRepo.getMyPartnerGroups();
      if (mounted) setState(() { _partnerGroups = groups; _loadingGroups = false; });
    } catch (_) {
      if (mounted) setState(() { _partnerGroups = []; _loadingGroups = false; });
    }
  }

  void _onVisibilityChanged(String vis) {
    setState(() { _visibility = vis; _selectedGroupId = null; });
    if (vis == 'partner') _loadPartnerGroups();
  }

  void _showPartnerAdd() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PartnerAddSheet(
        partnerRepo: widget.partnerRepo,
        notifRepo: widget.notifRepo,
        myNickname: widget.myNickname,
      ),
    );
    _loadPartnerGroups();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    if (_visibility == 'partner' && _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파트너 그룹을 선택해주세요')),
      );
      return;
    }
    setState(() => _loading = true);
    await widget.repo.createPrayer(
      content: content,
      visibility: _visibility,
      partnerGroupId: _selectedGroupId,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14, right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기도제목 작성',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            // 그룹 선택
            Row(
              children: _groups.map((g) {
                final selected = _visibility == g.$2;
                return GestureDetector(
                  onTap: () => _onVisibilityChanged(g.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AC.light.withOpacity(0.18) : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AC.light.withOpacity(0.6) : Colors.white12),
                    ),
                    child: Text(g.$1,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? AC.light : AC.muted)),
                  ),
                );
              }).toList(),
            ),
            // 파트너 그룹 선택 영역
            if (_visibility == 'partner') ...[
              const SizedBox(height: 12),
              if (_loadingGroups)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              else ...[
                if (_partnerGroups.isNotEmpty) ...[
                  ...  _partnerGroups.map((g) {
                    final id = g['id'] as String;
                    final name = g['name'] as String? ?? '';
                    final selected = _selectedGroupId == id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGroupId = id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AC.light.withOpacity(0.12) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AC.light.withOpacity(0.5) : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 16,
                              color: selected ? AC.light : AC.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(name,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: selected ? AC.light : Colors.white,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                GestureDetector(
                  onTap: _showPartnerAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: AC.muted),
                        SizedBox(width: 6),
                        Text('파트너 추가하기',
                            style: TextStyle(fontSize: 12, color: AC.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                decoration: const InputDecoration(
                  hintText: '기도제목을 입력하세요...',
                  hintStyle: TextStyle(color: AC.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(color: AC.light.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))
                  ],
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1030)))
                    : const Text('작성 완료',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1030))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 기도하기 시트 ────────────────────────────────────────────

class _PrayListSheet extends StatefulWidget {
  final PrayerRepository repo;
  final String myNickname;
  const _PrayListSheet({required this.repo, required this.myNickname});

  @override
  State<_PrayListSheet> createState() => _PrayListSheetState();
}

class _PrayListSheetState extends State<_PrayListSheet> {
  List<Map<String, dynamic>> _prayers = [];
  bool _loading = true;
  final _myUid = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final myRaw = await widget.repo.getMyPrayers();
      final savedRaw = await widget.repo.getSavedPrayers();
      List<Map<String, dynamic>> partnerRaw = [];
      try { partnerRaw = await widget.repo.getPartnerPrayers(); } catch (_) {}

      final myPrayers = myRaw.map((p) => {...p, '_isMine': true, '_tag': 'mine'}).toList();
      final savedPrayers = <Map<String, dynamic>>[];
      for (final row in savedRaw) {
        final pr = row['prayer_requests'];
        if (pr is Map<String, dynamic> && pr['author_id'] != _myUid) {
          savedPrayers.add({...pr, '_isMine': false, '_tag': 'saved'});
        }
      }
      final partnerPrayers = partnerRaw.map((p) => {...p, '_isMine': false, '_tag': 'partner'}).toList();

      if (mounted) {
        setState(() {
          _prayers = [...myPrayers, ...savedPrayers, ...partnerPrayers];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _prayers = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E0A1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white12),
            left: BorderSide(color: Colors.white12),
            right: BorderSide(color: Colors.white12),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('기도하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_prayers.isEmpty)
              const Expanded(
                child: Center(child: Text('기도제목이 없습니다', style: TextStyle(color: AC.muted, fontSize: 14))),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: _prayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PrayItemCard(
                    prayer: _prayers[i],
                    repo: widget.repo,
                    myNickname: widget.myNickname,
                    onDeleted: () => setState(() => _prayers.removeAt(i)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrayItemCard extends StatefulWidget {
  final Map<String, dynamic> prayer;
  final PrayerRepository repo;
  final String myNickname;
  final VoidCallback onDeleted;
  const _PrayItemCard({
    required this.prayer,
    required this.repo,
    required this.myNickname,
    required this.onDeleted,
  });

  @override
  State<_PrayItemCard> createState() => _PrayItemCardState();
}

class _PrayItemCardState extends State<_PrayItemCard> {
  bool _praying = false;
  bool _loading = false;
  bool _isLeft = false;
  int _prayCount = 0;
  List<String> _prayNicknames = [];
  final _notifRepo = NotificationRepository();

  @override
  void initState() {
    super.initState();
    _isLeft = widget.prayer['is_left'] == true;
    _checkPraying();
    _loadPrayInfo();
  }

  Future<void> _checkPraying() async {
    final result = await widget.repo.isAlreadyPraying(widget.prayer['id'] as String);
    if (mounted) setState(() => _praying = result);
  }

  Future<void> _loadPrayInfo() async {
    final info = await widget.repo.getPrayerTogetherInfo(widget.prayer['id'] as String);
    if (mounted) setState(() {
      _prayCount = info['count'] as int;
      _prayNicknames = List<String>.from(info['nicknames'] as List);
    });
  }

  void _showPrayerUsers() {
    if (_prayCount == 0) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF0E0A1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white12),
            left: BorderSide(color: Colors.white12),
            right: BorderSide(color: Colors.white12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('$_prayCount명이 기도했어요',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _prayNicknames.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AC.light.withOpacity(0.15),
                          border: Border.all(color: AC.light.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            _prayNicknames[i].isNotEmpty ? _prayNicknames[i][0] : '?',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.light),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_prayNicknames[i],
                          style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
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

  Future<void> _pray() async {
    if (_loading) return;
    setState(() => _loading = true);
    final id = widget.prayer['id'] as String;
    if (_praying) {
      await widget.repo.unprayForPrayer(id);
      if (mounted) setState(() { _praying = false; _loading = false; });
    } else {
      await widget.repo.prayForPrayer(id);
      final authorId = widget.prayer['author_id'] as String?;
      if (authorId != null) {
        await _notifRepo.sendPrayNotification(
          recipientId: authorId,
          prayerRequestId: id,
          fromNickname: widget.myNickname,
        );
      }
      if (mounted) setState(() { _praying = true; _loading = false; });
    }
    _loadPrayInfo();
  }

  Future<void> _leave() async {
    if (_isLeft) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14102A),
        title: const Text('두고가기', style: TextStyle(color: Colors.white)),
        content: const Text('이 기도제목을 두고 가시겠어요?', style: TextStyle(color: AC.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('두고가기', style: TextStyle(color: AC.light)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.repo.leavePrayer(widget.prayer['id'] as String);
      if (mounted) setState(() => _isLeft = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.prayer['_isMine'] as bool? ?? false;
    final tag = widget.prayer['_tag'] as String? ?? '';
    final content = widget.prayer['content'] as String? ?? '';

    Color tagColor = AC.light;
    String tagLabel = '';
    if (tag == 'saved') { tagColor = AC.glass1; tagLabel = '담아둔'; }
    if (tag == 'partner') { tagColor = const Color(0xFFB39DDB); tagLabel = '파트너'; }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC14102A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMine)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AC.light.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: const Text('내 기도제목',
                  style: TextStyle(fontSize: 9, color: AC.light, fontWeight: FontWeight.w700)),
            )
          else if (tagLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(tagLabel,
                  style: TextStyle(fontSize: 9, color: tagColor, fontWeight: FontWeight.w700)),
            ),
          Text(content,
              style: const TextStyle(fontSize: 13, color: Color(0xFFE9E4FF), height: 1.6)),
          if (_prayCount > 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showPrayerUsers,
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 11, color: AC.glass1),
                  const SizedBox(width: 4),
                  Text(
                    '$_prayCount명이 기도했어요',
                    style: const TextStyle(fontSize: 11, color: AC.glass1, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 13, color: AC.glass1),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMine) ...[
                _ActionButton(
                  label: _isLeft ? '두고간 기도' : '두고가기',
                  icon: _isLeft ? Icons.mail_rounded : Icons.nightlight_round,
                  color: _isLeft ? const Color(0xFFFFC55E) : AC.muted,
                  onTap: _leave,
                ),
                const SizedBox(width: 8),
              ],
              _ActionButton(
                label: _loading ? '...' : (_praying ? '기도중' : '기도하기'),
                icon: _praying ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _praying ? AC.glass1 : AC.light,
                onTap: _pray,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── 봉투 위젯 ───────────────────────────────────────────────

class _EnvelopeWidget extends StatefulWidget {
  final Map<String, dynamic> prayer;
  final PrayerRepository repo;
  final BoxConstraints constraints;
  final VoidCallback onSaved;
  const _EnvelopeWidget({
    required this.prayer,
    required this.repo,
    required this.constraints,
    required this.onSaved,
  });

  @override
  State<_EnvelopeWidget> createState() => _EnvelopeWidgetState();
}

class _EnvelopeWidgetState extends State<_EnvelopeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  Offset get _pos {
    final hash = (widget.prayer['id'] as String).hashCode.abs();
    final x = (12 + (hash % 74)) / 100 * widget.constraints.maxWidth;
    final y = (28 + ((hash ~/ 83) % 44)) / 100 * widget.constraints.maxHeight;
    return Offset(x, y);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EnvelopeDetailSheet(prayer: widget.prayer, repo: widget.repo),
    ).then((_) => widget.onSaved());
  }

  @override
  Widget build(BuildContext context) {
    final pos = _pos;
    return Positioned(
      left: pos.dx - 20, top: pos.dy - 20,
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -3 * _anim.value),
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC55E).withOpacity(0.35 + 0.15 * _anim.value),
                      blurRadius: 16, spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1530),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFC55E).withOpacity(0.6), width: 1.5),
                ),
                child: const Icon(Icons.mail_outline_rounded, color: Color(0xFFFFC55E), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 봉투 담기 시트 ───────────────────────────────────────────

class _EnvelopeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> prayer;
  final PrayerRepository repo;
  const _EnvelopeDetailSheet({required this.prayer, required this.repo});

  @override
  State<_EnvelopeDetailSheet> createState() => _EnvelopeDetailSheetState();
}

class _EnvelopeDetailSheetState extends State<_EnvelopeDetailSheet> {
  bool _saved = false;
  bool _loading = false;

  Future<void> _save() async {
    if (_loading || _saved) return;
    setState(() => _loading = true);
    try {
      await widget.repo.savePrayer(widget.prayer['id'] as String);
      if (mounted) setState(() { _saved = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _saved = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.prayer['content'] as String? ?? '';
    final authorNickname = widget.prayer['_author_nickname'] as String? ?? '';

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
                    color: const Color(0xFFFFC55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline_rounded, size: 11, color: Color(0xFFFFC55E)),
                      const SizedBox(width: 4),
                      Text(
                        authorNickname.isNotEmpty ? '$authorNickname 의 기도' : '두고간 기도',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFFFC55E), fontWeight: FontWeight.w700)),
                    ],
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
            GestureDetector(
              onTap: _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity, height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _saved
                      ? LinearGradient(colors: [AC.glass1.withOpacity(0.25), AC.glass1.withOpacity(0.1)])
                      : const LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)]),
                  border: _saved ? Border.all(color: AC.glass1.withOpacity(0.5)) : null,
                  boxShadow: _saved ? [] : [BoxShadow(
                    color: AC.light.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1030)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 16,
                            color: _saved ? AC.glass1 : const Color(0xFF1A1030),
                          ),
                          const SizedBox(width: 8),
                          Text(_saved ? '담아둠' : '담기',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: _saved ? AC.glass1 : const Color(0xFF1A1030))),
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

// ─── 순위 시트 ────────────────────────────────────────────────

class _RankingSheet extends StatefulWidget {
  final PrayerRepository repo;
  const _RankingSheet({required this.repo});

  @override
  State<_RankingSheet> createState() => _RankingSheetState();
}

class _RankingSheetState extends State<_RankingSheet> {
  List<Map<String, dynamic>> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.repo.getWeeklyRanking();
    if (mounted) setState(() { _ranking = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8, minChildSize: 0.4, maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E0A1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white12),
            left: BorderSide(color: Colors.white12),
            right: BorderSide(color: Colors.white12),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('이번주 기도 순위',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_ranking.isEmpty)
              const Expanded(
                child: Center(child: Text('아직 기도 기록이 없습니다', style: TextStyle(color: AC.muted, fontSize: 14))),
              )
            else
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    _buildTop3(),
                    const SizedBox(height: 20),
                    for (var i = 3; i < _ranking.length; i++) _buildRankItem(i + 1, _ranking[i]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop3() {
    const medals = ['🥇', '🥈', '🥉'];
    const colors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];
    final slots = [_ranking.length > 1 ? 1 : null, 0, _ranking.length > 2 ? 2 : null];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: slots.map((idx) {
        if (idx == null) return const Expanded(child: SizedBox());
        final item = _ranking[idx];
        final isFirst = idx == 0;
        return Expanded(
          child: Column(
            children: [
              Text(medals[idx], style: TextStyle(fontSize: isFirst ? 34 : 26)),
              const SizedBox(height: 6),
              Container(
                width: isFirst ? 60 : 50, height: isFirst ? 60 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[idx].withOpacity(0.15),
                  border: Border.all(color: colors[idx].withOpacity(0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    (item['nickname'] as String? ?? '?')[0],
                    style: TextStyle(
                        fontSize: isFirst ? 22 : 18, fontWeight: FontWeight.w800, color: colors[idx]),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(item['nickname'] as String? ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text('${item['count']}번', style: TextStyle(fontSize: 11, color: colors[idx])),
              SizedBox(height: isFirst ? 0 : 8),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRankItem(int rank, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC14102A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(width: 28,
              child: Text('$rank',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.muted))),
          const SizedBox(width: 8),
          Expanded(child: Text(item['nickname'] as String? ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600))),
          Text('${item['count']}번',
              style: const TextStyle(fontSize: 13, color: AC.glass1, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── 알림 페이지 ──────────────────────────────────────────────

class _NotificationsPage extends StatefulWidget {
  final NotificationRepository notifRepo;
  final PartnerRepository partnerRepo;
  const _NotificationsPage({required this.notifRepo, required this.partnerRepo});

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
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

  Future<void> _acceptInvite(Map<String, dynamic> notif) async {
    final groupId = notif['url'] as String?;
    if (groupId == null) return;
    try {
      await widget.partnerRepo.acceptInvite(groupId);
      await widget.notifRepo.markAsRead(notif['id'] as String);
      _load();
    } catch (_) {}
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('알림',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
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
                    itemBuilder: (_, i) => _buildNotifItem(_notifs[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifItem(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? '';
    final message = notif['message'] as String? ?? '';
    final isRead = notif['is_read'] as bool? ?? false;
    final isInvite = type == 'partner_invite';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xCC14102A) : const Color(0xFF1E1840),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isRead ? Colors.white12 : AC.light.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInvite ? Icons.people_rounded : Icons.favorite_rounded,
                size: 14,
                color: isInvite ? const Color(0xFFB39DDB) : AC.glass1,
              ),
              const SizedBox(width: 6),
              Text(
                isInvite ? '파트너 초대' : '기도',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isInvite ? const Color(0xFFB39DDB) : AC.glass1),
              ),
              if (!isRead) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Color(0xFFFF4D4D), shape: BoxShape.circle),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFE9E4FF), height: 1.5)),
          if (isInvite) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _acceptInvite(notif),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB39DDB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB39DDB).withOpacity(0.4)),
                ),
                child: const Text('수락하기',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFB39DDB), fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 파트너 추가 시트 ─────────────────────────────────────────

class _PartnerAddSheet extends StatefulWidget {
  final PartnerRepository partnerRepo;
  final NotificationRepository notifRepo;
  final String myNickname;
  const _PartnerAddSheet({
    required this.partnerRepo,
    required this.notifRepo,
    required this.myNickname,
  });

  @override
  State<_PartnerAddSheet> createState() => _PartnerAddSheetState();
}

class _PartnerAddSheetState extends State<_PartnerAddSheet> {
  final _nameController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  Set<String> _selectedIds = {};
  bool _loadingMembers = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final members = await widget.partnerRepo.getChurchMembers();
    if (mounted) setState(() { _members = members; _loadingMembers = false; });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파트너 그룹 이름을 입력해주세요')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('멤버를 1명 이상 선택해주세요')),
      );
      return;
    }
    setState(() => _submitting = true);
    final groupId = await widget.partnerRepo.createPartnerGroup(
      name: name,
      memberIds: _selectedIds.toList(),
    );
    // 초대 알림 전송
    for (final memberId in _selectedIds) {
      await widget.notifRepo.sendPartnerInviteNotification(
        recipientId: memberId,
        partnerGroupId: groupId,
        partnerGroupName: name,
        fromNickname: widget.myNickname,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14, right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('파트너 추가하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
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
            // 그룹 이름
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '파트너 그룹 이름',
                  hintStyle: TextStyle(color: AC.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('멤버 선택',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AC.muted)),
            const SizedBox(height: 8),
            if (_loadingMembers)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('교회 멤버가 없습니다', style: TextStyle(color: AC.muted, fontSize: 13)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  itemBuilder: (_, i) {
                    final member = _members[i];
                    final id = member['id'] as String;
                    final nickname = member['nickname'] as String? ?? '';
                    final selected = _selectedIds.contains(id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) _selectedIds.remove(id);
                        else _selectedIds.add(id);
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFB39DDB).withOpacity(0.12)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? const Color(0xFFB39DDB).withOpacity(0.5) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: selected ? const Color(0xFFB39DDB) : AC.muted,
                            ),
                            const SizedBox(width: 10),
                            Text(nickname,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: selected ? Colors.white : AC.muted,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _submitting ? null : _submit,
              child: Container(
                width: double.infinity, height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB39DDB), Color(0xFF9C7FC4)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFB39DDB).withOpacity(0.35),
                        blurRadius: 18, offset: const Offset(0, 6))
                  ],
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('파트너 추가',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                  center: Alignment(0, -0.5), radius: 1.1,
                  colors: [Color(0xFF2A1505), Color(0xFF120D20), Color(0xFF06030F)],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0, height: c.maxHeight * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [const Color(0xFF1A0D03).withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: c.maxHeight * 0.10, left: c.maxWidth / 2 - 70,
            child: const _CandleGlow(),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center, radius: 1.0,
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
    vsync: this, duration: const Duration(milliseconds: 1800),
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
        width: 140, height: 140,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Color(0x88FFAA44), Colors.transparent]),
        ),
      ),
    );
  }
}
