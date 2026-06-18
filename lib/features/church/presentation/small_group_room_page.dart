import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/cell_group_repository.dart';
import '../data/church_presence_service.dart';
import '../domain/avatar_user.dart';
import 'widgets/avatar_widgets.dart';
import 'widgets/room_nav.dart';

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

// ─── 소그룹 방 ────────────────────────────────────────────────

class SmallGroupRoomPage extends StatefulWidget {
  final String cellGroupId;
  final String groupName;
  const SmallGroupRoomPage({super.key, required this.cellGroupId, required this.groupName});

  @override
  State<SmallGroupRoomPage> createState() => _SmallGroupRoomPageState();
}

class _SmallGroupRoomPageState extends State<SmallGroupRoomPage>
    with SingleTickerProviderStateMixin {
  double _selfX = 50, _selfY = 72;
  List<AvatarUser> _onlineUsers = [];
  bool _isMember = false;
  bool _joining = false;

  final _repo = CellGroupRepository();
  final _presence = ChurchPresenceService();
  late final TabController _tab = TabController(length: 3, vsync: this);

  List<Map<String, dynamic>> _notices = [];
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
    _tab.dispose();
    _presence.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.cellGroupId;
    final results = await Future.wait([
      _repo.isMember(id),
      _repo.getMembers(id),
    ]);
    final member = results[0] as bool;

    List<Map<String, dynamic>> notices = [];
    List<Map<String, dynamic>> sharing = [];
    if (member) {
      final content = await Future.wait([_repo.getNotices(id), _repo.getSharing(id)]);
      notices = content[0];
      sharing = content[1];
    }

    if (mounted) {
      setState(() {
        _isMember = member;
        _members = results[1] as List<Map<String, dynamic>>;
        _notices = notices;
        _sharing = sharing;
        _loading = false;
      });
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
    final results = await Future.wait([
      _repo.getNotices(widget.cellGroupId),
      _repo.getSharing(widget.cellGroupId),
      _repo.getMembers(widget.cellGroupId),
    ]);
    if (mounted) {
      setState(() {
        _isMember = true;
        _notices = results[0];
        _sharing = results[1];
        _members = results[2];
        _joining = false;
      });
    }
  }

  void _onTapBackground(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx / constraints.maxWidth * 100;
    final y = details.localPosition.dy / constraints.maxHeight * 100;
    if (y < 48 || y > 88) return;
    setState(() {
      _selfX = x.clamp(8, 92);
      _selfY = y.clamp(48, 88);
    });
    _presence.updatePosition(_selfX, _selfY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      bottomNavigationBar: const RoomNavBar(current: RoomType.smallGroup),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _onTapBackground(d, constraints),
              child: Stack(
                children: [
                  const Positioned.fill(child: _SmallGroupBg()),
                  // 상단 콘텐츠 영역
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: constraints.maxHeight * 0.48,
                    child: _buildContentArea(constraints),
                  ),
                  for (var i = 0; i < _onlineUsers.length; i++)
                    _buildUserAvatar(_onlineUsers[i], constraints, i),
                  _buildSelfAvatar(constraints),
                  Positioned(
                    left: 0, right: 0,
                    bottom: constraints.maxHeight * 0.11,
                    child: const IgnorePointer(
                      child: Text(
                        '바닥을 탭하면 이동해요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5, color: AC.muted,
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
        ],
      ),
      floatingActionButton: _isMember && !_loading ? _buildFab() : null,
    );
  }

  Widget _buildContentArea(BoxConstraints constraints) {
    final topPad = MediaQuery.of(context).padding.top + constraints.maxHeight * 0.09;
    if (!_isMember && !_loading) {
      return Column(
        children: [
          SizedBox(height: topPad + 16),
          Glass(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_rounded, size: 36, color: AC.muted),
                const SizedBox(height: 10),
                Text('${widget.groupName}에 참여하면\n공지와 나눔을 볼 수 있어요',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AC.muted, height: 1.5)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _joining ? null : _join,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                      ),
                    ),
                    child: Text(
                      _joining ? '참여 중...' : '소그룹 참여하기',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1030)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(height: topPad),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: AC.glass2.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AC.glass2.withOpacity(0.5)),
            ),
            labelColor: AC.glass2,
            unselectedLabelColor: AC.muted,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(3),
            tabs: const [Tab(text: '공지'), Tab(text: '나눔'), Tab(text: '멤버')],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: [
                    _buildNoticeTab(),
                    _buildSharingTab(),
                    _buildMemberTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNoticeTab() {
    if (_notices.isEmpty) {
      return const Center(
        child: Text('등록된 공지가 없어요', style: TextStyle(color: AC.muted, fontSize: 13)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _notices.length,
      itemBuilder: (_, i) {
        final n = _notices[i];
        final date = (n['created_at'] as String?)?.substring(0, 10) ?? '';
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
              Text(n['content'] as String,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE9E4FF), height: 1.5)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(fontSize: 10, color: AC.muted)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharingTab() {
    if (_sharing.isEmpty) {
      return const Center(
        child: Text('등록된 나눔이 없어요', style: TextStyle(color: AC.muted, fontSize: 13)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _sharing.length,
      itemBuilder: (_, i) {
        final s = _sharing[i];
        final date = (s['created_at'] as String?)?.substring(0, 10) ?? '';
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
              Text(s['title'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              Text(s['content'] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFCFC9E8), height: 1.5)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(fontSize: 10, color: AC.muted)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberTab() {
    if (_members.isEmpty) {
      return const Center(
        child: Text('멤버가 없어요', style: TextStyle(color: AC.muted, fontSize: 13)));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
      ),
      itemCount: _members.length,
      itemBuilder: (_, i) {
        final nickname = _members[i]['nickname'] as String? ?? '?';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AC.glass2.withOpacity(0.2),
                ),
                child: const Icon(Icons.person_rounded, size: 20, color: AC.glass2),
              ),
              const SizedBox(height: 6),
              Text(nickname,
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: AC.glass2,
      onPressed: () => _showAddSheet(),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddContentSheet(
        tab: _tab.index,
        cellGroupId: widget.cellGroupId,
        repo: _repo,
        onAdded: _load,
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
                radius: 999, padding: const EdgeInsets.all(10),
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
                  const Icon(Icons.groups_rounded, size: 14, color: AC.glass2),
                  const SizedBox(width: 6),
                  Text(widget.groupName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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
}

// ─── 공지/나눔 추가 시트 ──────────────────────────────────────

class _AddContentSheet extends StatefulWidget {
  final int tab;
  final String cellGroupId;
  final CellGroupRepository repo;
  final VoidCallback onAdded;
  const _AddContentSheet({
    required this.tab, required this.cellGroupId,
    required this.repo, required this.onAdded,
  });

  @override
  State<_AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends State<_AddContentSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  bool get _isSharing => widget.tab == 1;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _saving = true);
    if (_isSharing) {
      final title = _titleCtrl.text.trim();
      await widget.repo.addSharing(widget.cellGroupId, title.isEmpty ? '나눔' : title, content);
    } else {
      await widget.repo.addNotice(widget.cellGroupId, content);
    }
    widget.onAdded();
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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isSharing ? '나눔 추가' : '공지 추가',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 14),
            if (_isSharing) ...[
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '제목',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isSharing ? '나눔 내용을 입력하세요' : '공지 내용을 입력하세요',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AC.glass2,
                ),
                child: Text(_saving ? '저장 중...' : '저장',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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
        // 상단 따뜻한 빛
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
        // 비네트
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
