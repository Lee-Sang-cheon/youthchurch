import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/cell_group_repository.dart';
import '../data/church_presence_service.dart';
import '../domain/avatar_user.dart';
import 'widgets/avatar_widgets.dart';
import '../../home/presentation/challenge_tab.dart';
import 'group_photo_feed.dart';

// ─── 셀그룹 목록 시트 ──────────────────────────────────────

class SmallGroupListSheet extends StatefulWidget {
  const SmallGroupListSheet({super.key});

  @override
  State<SmallGroupListSheet> createState() => _SmallGroupListSheetState();
}

class _SmallGroupListSheetState extends State<SmallGroupListSheet> {
  final _repo = CellGroupRepository();
  List<Map<String, dynamic>> _groups = [];
  String? _myCellGroupId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.getCellGroups(),
        _repo.getMyCellGroupId(),
      ]);
      if (mounted) {
        setState(() {
          _groups = results[0] as List<Map<String, dynamic>>;
          _myCellGroupId = results[1] as String?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(onCreated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('소그룹',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: _showCreateSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AC.glass2.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AC.glass2.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 13, color: AC.glass2),
                        SizedBox(width: 4),
                        Text('추가', style: TextStyle(fontSize: 11, color: AC.glass2, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 4),
            const Text('입장할 소그룹을 선택하세요',
                style: TextStyle(fontSize: 13, color: AC.muted)),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_groups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('등록된 소그룹이 없어요', style: TextStyle(color: AC.muted, fontSize: 13)),
                ),
              )
            else
              ...(_groups.map((g) => _GroupTile(
                group: g,
                isMine: g['id'] == _myCellGroupId,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmallGroupRoomPage(
                        cellGroupId: g['id'] as String,
                        groupName: g['name'] as String,
                      ),
                    ),
                  );
                },
              ))),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isMine;
  final VoidCallback onTap;
  const _GroupTile({required this.group, required this.isMine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isMine ? AC.glass2.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine ? AC.glass2.withOpacity(0.5) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_rounded, size: 20, color: AC.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group['name'] as String,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            if (isMine)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AC.glass2.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('내 소그룹',
                    style: TextStyle(fontSize: 10, color: AC.glass2, fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AC.muted),
          ],
        ),
      ),
    );
  }
}

// ─── 소그룹 만들기 시트 ───────────────────────────────────────

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
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final user = await _client.from('users').select('church_id').eq('id', uid).maybeSingle();
    final churchId = user?['church_id'] as String?;
    if (churchId == null) {
      if (mounted) setState(() => _loadingMembers = false);
      return;
    }
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
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      final user = await _client.from('users').select('church_id').eq('id', uid).maybeSingle();
      final churchId = user?['church_id'] as String?;
      if (churchId == null) return;
      final group = await _client
          .from('cell_groups')
          .insert({'name': name, 'church_id': churchId})
          .select()
          .single();
      final groupId = group['id'] as String;
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
            const Text('소그룹 만들기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            Glass(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
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
                            if (selected)
                              const Icon(Icons.check_circle_rounded, color: AC.glass2, size: 18)
                            else
                              const Icon(Icons.circle_outlined, color: AC.muted, size: 18),
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

// ─── 소그룹 방 ────────────────────────────────────────────────

class SmallGroupRoomPage extends StatefulWidget {
  final String cellGroupId;
  final String groupName;
  const SmallGroupRoomPage({super.key, required this.cellGroupId, required this.groupName});

  @override
  State<SmallGroupRoomPage> createState() => _SmallGroupRoomPageState();
}

class _SmallGroupRoomPageState extends State<SmallGroupRoomPage> {
  double _selfX = 50, _selfY = 60;
  List<AvatarUser> _onlineUsers = [];
  bool _isMember = false;
  bool _joining = false;

  final _repo = CellGroupRepository();
  final _presence = ChurchPresenceService();

  List<Map<String, dynamic>> _feed = [];
  List<Map<String, dynamic>> _sharing = [];
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

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
    if (mounted) setState(() => _loading = true);
    try {
      final id = widget.cellGroupId;
      final isMember = await _repo.isMember(id);
      final memberList = await _repo.getMembers(id);

      List<Map<String, dynamic>> feed = [];
      List<Map<String, dynamic>> sharing = [];
      if (isMember) {
        final results = await Future.wait([_repo.getFeed(id), _repo.getSharing(id)]);
        feed = results[0];
        sharing = results[1];
      }

      if (mounted) {
        setState(() {
          _isMember = isMember;
          _members = memberList;
          _feed = feed;
          _sharing = sharing;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    await _presence.join(
      nickname: _myNickname,
      x: _selfX,
      y: _selfY,
      room: 'cell_${widget.cellGroupId}',
    );
    _presence.usersStream.listen((users) {
      if (mounted) setState(() => _onlineUsers = users);
    });
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    await _repo.joinGroup(widget.cellGroupId);
    await _load();
    if (mounted) setState(() => _joining = false);
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

  void _showFeed() {
    if (!_isMember) { _showJoinPrompt(); return; }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FeedSheet(
        feed: _feed,
        loading: _loading,
        cellGroupId: widget.cellGroupId,
        repo: _repo,
        onRefresh: _load,
      ),
    );
  }

  void _showSharing() {
    if (!_isMember) { _showJoinPrompt(); return; }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SharingSheet(
        sharing: _sharing,
        loading: _loading,
        cellGroupId: widget.cellGroupId,
        repo: _repo,
        onRefresh: _load,
      ),
    );
  }

  void _showMemberSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MembersSheet(
        members: _members,
        isMember: _isMember,
        joining: _joining,
        cellGroupId: widget.cellGroupId,
        repo: _repo,
        onJoin: _join,
        onRefresh: _load,
      ),
    );
  }

  void _showJoinPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
        child: Glass(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_rounded, size: 36, color: AC.muted),
              const SizedBox(height: 10),
              Text('${widget.groupName}에 참여하면\n공지와 나눔을 볼 수 있어요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AC.muted, height: 1.5)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () { Navigator.pop(context); _join(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                    ),
                  ),
                  child: const Text('소그룹 참여하기',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1030))),
                ),
              ),
            ],
          ),
        ),
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
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _onTapBackground(d, constraints),
              child: Stack(
                children: [
                  const Positioned.fill(child: _SmallGroupBg()),
                  ..._buildPerspectiveSortedAvatars(constraints),
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

  double _perspectiveScale(double yPct) {
    final t = ((yPct - 15) / (88 - 15)).clamp(0.0, 1.0);
    return 0.55 + 0.65 * t;
  }

  Widget _buildUserAvatar(AvatarUser user, BoxConstraints c, int index) {
    final scale = _perspectiveScale(user.y);
    final x = user.x / 100 * c.maxWidth;
    final y = user.y / 100 * c.maxHeight;
    return Positioned(
      left: x - 30, top: y - 40,
      child: AvatarFigure(user: user.copyWith(scale: scale), seed: index),
    );
  }

  Widget _buildSelfAvatar(BoxConstraints c) {
    final scale = _perspectiveScale(_selfY);
    final x = _selfX / 100 * c.maxWidth;
    final y = _selfY / 100 * c.maxHeight;
    return AnimatedPositioned(
      key: const ValueKey('self'),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: x - 30, top: y - 80,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: SelfAvatar(nickname: _myNickname),
      ),
    );
  }

  List<Widget> _buildPerspectiveSortedAvatars(BoxConstraints c) {
    final items = <(double y, Widget w)>[];
    for (var i = 0; i < _onlineUsers.length; i++) {
      items.add((_onlineUsers[i].y, _buildUserAvatar(_onlineUsers[i], c, i)));
    }
    items.add((_selfY, _buildSelfAvatar(c)));
    items.sort((a, b) => a.$1.compareTo(b.$1));
    return items.map((e) => e.$2).toList();
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
                radius: 999, padding: const EdgeInsets.all(10),
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
                  const Icon(Icons.groups_rounded, size: 14, color: AC.glass2),
                  const SizedBox(width: 6),
                  Text(widget.groupName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 13, color: Colors.white24),
                  const SizedBox(width: 8),
                  Text('${_onlineUsers.length + 1}명',
                      style: const TextStyle(fontSize: 12, color: AC.muted)),
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
            _NavItem(icon: Icons.dynamic_feed_rounded, label: '피드', onTap: _showFeed),
            _NavItem(icon: Icons.menu_book_rounded, label: '나눔지', onTap: _showSharing),
            _NavItem(icon: Icons.people_rounded, label: '구성원', onTap: _showMemberSheet),
            _NavItem(
              icon: Icons.photo_camera_rounded,
              label: '순간',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _GroupMomentPage(cellGroupId: widget.cellGroupId, groupName: widget.groupName),
              )),
            ),
            _NavItem(
              icon: Icons.emoji_events_rounded,
              label: '챌린지',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeTab())),
            ),
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

// ─── 피드 시트 ────────────────────────────────────────────────

class _FeedSheet extends StatefulWidget {
  final List<Map<String, dynamic>> feed;
  final bool loading;
  final String cellGroupId;
  final CellGroupRepository repo;
  final VoidCallback onRefresh;
  const _FeedSheet({
    required this.feed,
    required this.loading,
    required this.cellGroupId,
    required this.repo,
    required this.onRefresh,
  });

  @override
  State<_FeedSheet> createState() => _FeedSheetState();
}

class _FeedSheetState extends State<_FeedSheet> {
  late List<Map<String, dynamic>> _feed;

  @override
  void initState() {
    super.initState();
    _feed = widget.feed;
  }

  void _showCompose(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ComposeSheet(
        defaultType: 'notice',
        cellGroupId: widget.cellGroupId,
        repo: widget.repo,
        onAdded: () {
          widget.onRefresh();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, controller) => Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  const Text('피드',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showCompose(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AC.glass2.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AC.glass2.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: AC.glass2),
                          SizedBox(width: 5),
                          Text('작성', style: TextStyle(fontSize: 12, color: AC.glass2, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _feed.isEmpty
                      ? const Center(
                          child: Text('게시된 내용이 없어요\n작성 버튼으로 공지나 나눔을 올려보세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AC.muted, fontSize: 13, height: 1.5)),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _feed.length,
                          itemBuilder: (_, i) {
                            final item = _feed[i];
                            final isSharing = (item['_type'] as String?) == 'sharing';
                            final date = (item['created_at'] as String?)?.substring(0, 10) ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isSharing ? const Color(0xFF7E57C2) : AC.glass1).withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isSharing ? '나눔' : '공지',
                                          style: TextStyle(
                                            fontSize: 9, fontWeight: FontWeight.w700,
                                            color: isSharing ? const Color(0xFFB39DDB) : AC.glass1,
                                          ),
                                        ),
                                      ),
                                      if (isSharing && (item['title'] as String?)?.isNotEmpty == true) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(item['title'] as String,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ] else
                                        const Spacer(),
                                      Text(date, style: const TextStyle(fontSize: 10, color: AC.muted)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item['content'] as String? ?? '',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFE9E4FF), height: 1.5),
                                      maxLines: 3, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 나눔지 시트 ──────────────────────────────────────────────

class _SharingSheet extends StatelessWidget {
  final List<Map<String, dynamic>> sharing;
  final bool loading;
  final String cellGroupId;
  final CellGroupRepository repo;
  final VoidCallback onRefresh;
  const _SharingSheet({
    required this.sharing,
    required this.loading,
    required this.cellGroupId,
    required this.repo,
    required this.onRefresh,
  });

  void _showCompose(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ComposeSheet(
        defaultType: 'sharing',
        cellGroupId: cellGroupId,
        repo: repo,
        onAdded: () {
          onRefresh();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, controller) => Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  const Text('나눔지',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showCompose(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7E57C2).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF7E57C2).withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: Color(0xFFB39DDB)),
                          SizedBox(width: 5),
                          Text('작성', style: TextStyle(fontSize: 12, color: Color(0xFFB39DDB), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : sharing.isEmpty
                      ? const Center(
                          child: Text('등록된 나눔지가 없어요\n목사님이 올려주실 예정이에요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AC.muted, fontSize: 13, height: 1.5)),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: sharing.length,
                          itemBuilder: (_, i) {
                            final s = sharing[i];
                            final date = (s['created_at'] as String?)?.substring(0, 10) ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1035).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF7E57C2).withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.menu_book_rounded, size: 13, color: Color(0xFFB39DDB)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(s['title'] as String? ?? '나눔지',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ),
                                      Text(date, style: const TextStyle(fontSize: 10, color: AC.muted)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(s['content'] as String? ?? '',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFCFC9E8), height: 1.5)),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 구성원 시트 ──────────────────────────────────────────────

class _MembersSheet extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final bool isMember;
  final bool joining;
  final String cellGroupId;
  final CellGroupRepository repo;
  final VoidCallback onJoin;
  final VoidCallback onRefresh;
  const _MembersSheet({
    required this.members,
    required this.isMember,
    required this.joining,
    required this.cellGroupId,
    required this.repo,
    required this.onJoin,
    required this.onRefresh,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  void _showInvite(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InviteMemberSheet(
        cellGroupId: widget.cellGroupId,
        repo: widget.repo,
        onInvited: widget.onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, controller) => Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  const Text('구성원',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  if (widget.isMember)
                    GestureDetector(
                      onTap: () => _showInvite(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AC.glass2.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AC.glass2.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded, size: 12, color: AC.glass2),
                            SizedBox(width: 5),
                            Text('초대', style: TextStyle(fontSize: 12, color: AC.glass2, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!widget.isMember)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: widget.joining ? null : widget.onJoin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)]),
                    ),
                    child: Text(
                      widget.joining ? '참여 중...' : '소그룹 참여하기',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1030)),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: widget.members.isEmpty
                  ? const Center(child: Text('멤버가 없어요', style: TextStyle(color: AC.muted, fontSize: 13)))
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: widget.members.length,
                      itemBuilder: (_, i) {
                        final nickname = widget.members[i]['nickname'] as String? ?? '?';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AC.glass2.withOpacity(0.2),
                                ),
                                child: Center(
                                  child: Text(
                                    nickname.isNotEmpty ? nickname[0] : '?',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.glass2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(nickname,
                                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 멤버 초대 시트 ───────────────────────────────────────────

class _InviteMemberSheet extends StatefulWidget {
  final String cellGroupId;
  final CellGroupRepository repo;
  final VoidCallback onInvited;
  const _InviteMemberSheet({
    required this.cellGroupId,
    required this.repo,
    required this.onInvited,
  });

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  List<Map<String, dynamic>> _available = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await widget.repo.getChurchMembersNotInGroup(widget.cellGroupId);
      if (mounted) setState(() { _available = members; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _available = []; _loading = false; });
    }
  }

  Future<void> _invite() async {
    if (_selected.isEmpty || _inviting) return;
    setState(() => _inviting = true);
    for (final uid in _selected) {
      await widget.repo.inviteMember(widget.cellGroupId, uid);
    }
    widget.onInvited();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('멤버 초대하기',
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
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_available.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('초대 가능한 멤버가 없어요', style: TextStyle(color: AC.muted, fontSize: 13))),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _available.length,
                  itemBuilder: (_, i) {
                    final m = _available[i];
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
                          color: selected ? AC.glass2.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AC.glass2.withOpacity(0.5) : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AC.glass2.withOpacity(0.2)),
                              child: Center(
                                child: Text(nickname.isNotEmpty ? nickname[0] : '?',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.glass2)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(nickname, style: const TextStyle(color: Colors.white, fontSize: 14))),
                            if (selected)
                              const Icon(Icons.check_circle_rounded, color: AC.glass2, size: 18)
                            else
                              const Icon(Icons.circle_outlined, color: AC.muted, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_available.isNotEmpty) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _invite,
                child: Container(
                  width: double.infinity, height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _selected.isEmpty ? AC.glass2.withOpacity(0.3) : AC.glass2,
                  ),
                  child: _inviting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _selected.isEmpty ? '초대할 멤버를 선택하세요' : '${_selected.length}명 초대하기',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 공지/나눔 작성 시트 ──────────────────────────────────────

class _ComposeSheet extends StatefulWidget {
  final String defaultType;
  final String cellGroupId;
  final CellGroupRepository repo;
  final VoidCallback onAdded;
  const _ComposeSheet({
    required this.defaultType,
    required this.cellGroupId,
    required this.repo,
    required this.onAdded,
  });

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late String _type;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _isSharing => _type == 'sharing';

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _saving = true);
    if (_isSharing) {
      final title = _titleCtrl.text.trim();
      await widget.repo.addSharing(widget.cellGroupId, title.isEmpty ? '나눔지' : title, content);
    } else {
      await widget.repo.addNotice(widget.cellGroupId, content);
    }
    widget.onAdded();
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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final entry in [('공지', 'notice'), ('나눔지', 'sharing')])
                  GestureDetector(
                    onTap: () => setState(() => _type = entry.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _type == entry.$2
                            ? AC.glass2.withOpacity(0.2)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _type == entry.$2 ? AC.glass2.withOpacity(0.6) : Colors.white12,
                        ),
                      ),
                      child: Text(entry.$1,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: _type == entry.$2 ? AC.glass2 : AC.muted)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isSharing) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '나눔지 제목 (예: 2025년 24주차)',
                    hintStyle: TextStyle(color: AC.muted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _contentCtrl,
                maxLines: 5,
                autofocus: !_isSharing,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  hintText: _isSharing ? '나눔지 내용을 입력하세요...' : '공지 내용을 입력하세요...',
                  hintStyle: const TextStyle(color: AC.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity, height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AC.glass2,
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('게시하기',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 소그룹 배경 ──────────────────────────────────────────────

class _SmallGroupBg extends StatelessWidget {
  const _SmallGroupBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [Color(0xFF1A1035), Color(0xFF0D0A1E), Color(0xFF060412)],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60, left: -40, right: -40,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [AC.glass2.withOpacity(0.18), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Colors.transparent, Color(0xCC04020A)],
                  stops: [0.4, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 순간 공유 페이지 ─────────────────────────────────────────

class _GroupMomentPage extends StatelessWidget {
  final String cellGroupId;
  final String groupName;
  const _GroupMomentPage({required this.cellGroupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('순간 공유', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(groupName, style: const TextStyle(color: AC.muted, fontSize: 11)),
          ],
        ),
      ),
      body: GroupPhotoFeed(cellGroupId: cellGroupId),
    );
  }
}
