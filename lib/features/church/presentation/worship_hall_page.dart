import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/church_content_repository.dart';
import '../data/church_presence_service.dart';
import '../domain/avatar_user.dart';
import 'widgets/church_scene_bg.dart';
import 'widgets/avatar_widgets.dart';
import 'my_page.dart';

class WorshipHallPage extends StatefulWidget {
  const WorshipHallPage({super.key});

  @override
  State<WorshipHallPage> createState() => _WorshipHallPageState();
}

class _WorshipHallPageState extends State<WorshipHallPage> {
  double _selfX = 50, _selfY = 60;
  List<AvatarUser> _onlineUsers = [];
  List<Map<String, dynamic>> _worships = [];
  bool _loading = true;

  final _repo = ChurchContentRepository();
  final _presence = ChurchPresenceService();

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
    try {
      final worships = await _repo.getWeeklyWorship();
      if (mounted) setState(() { _worships = worships; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _worships = []; _loading = false; });
    }
    await _presence.join(nickname: _myNickname, x: _selfX, y: _selfY, room: 'worship');
    _presence.usersStream.listen((users) {
      if (mounted) setState(() => _onlineUsers = users);
    });
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

  void _showSheet(int tabIndex) {
    if (tabIndex == 2) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _NoteSheet(repo: _repo),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WorshipSheet(
        tabIndex: tabIndex,
        worships: _worships,
        loading: _loading,
        onCopy: (url) {
          Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크가 복사됐어요'), duration: Duration(seconds: 2)),
          );
        },
        onShowImage: (url) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: Image.network(url, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, color: Colors.white54)),
                    ),
                  ),
                  SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _onTapBackground(d, constraints),
              child: Stack(
                children: [
                  const Positioned.fill(child: WorshipScene()),
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
                  const Icon(Icons.church_rounded, size: 14, color: AC.light),
                  const SizedBox(width: 6),
                  const Text('예배당',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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
            _NavItem(icon: Icons.article_rounded, label: '주보', onTap: () => _showSheet(0)),
            _NavItem(icon: Icons.play_circle_rounded, label: '예배 다시보기', onTap: () => _showSheet(1)),
            _NavItem(icon: Icons.edit_note_rounded, label: '예배노트', onTap: () => _showSheet(2)),
            _NavItem(
              icon: Icons.person_rounded,
              label: '마이페이지',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPage())),
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

// ─── 예배당 콘텐츠 시트 ───────────────────────────────────────

class _WorshipSheet extends StatelessWidget {
  final int tabIndex;
  final List<Map<String, dynamic>> worships;
  final bool loading;
  final void Function(String url) onCopy;
  final void Function(String url) onShowImage;

  const _WorshipSheet({
    required this.tabIndex,
    required this.worships,
    required this.loading,
    required this.onCopy,
    required this.onShowImage,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['주보', '예배 다시보기'];
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(titles[tabIndex],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            Expanded(child: _buildContent(ctx, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController controller) {
    if (tabIndex == 0) return _buildBulletin(controller);
    return _buildReplay(controller);
  }

  Widget _buildBulletin(ScrollController controller) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final items = worships.where((w) => w['bulletin_url'] != null).toList();
    if (items.isEmpty) {
      return const Center(child: Text('등록된 주보가 없어요', style: TextStyle(color: AC.muted, fontSize: 13)));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final w = items[i];
        final title = w['title'] as String? ?? '주보';
        final date = (w['date'] as String?)?.substring(0, 10) ?? '';
        final url = w['bulletin_url'] as String;
        return GestureDetector(
          onTap: () => onShowImage(url),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xCC14102A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AC.light.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AC.light.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.article_rounded, color: AC.light, size: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(date, style: const TextStyle(fontSize: 11, color: AC.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, size: 14, color: AC.muted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplay(ScrollController controller) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final items = worships.where((w) => w['replay_url'] != null).toList();
    if (items.isEmpty) {
      return const Center(child: Text('등록된 다시보기가 없어요', style: TextStyle(color: AC.muted, fontSize: 13)));
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final w = items[i];
        final title = w['title'] as String? ?? '예배';
        final date = (w['date'] as String?)?.substring(0, 10) ?? '';
        final url = w['replay_url'] as String;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xCC14102A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AC.light.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AC.light.withOpacity(0.12),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AC.light, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(date, style: const TextStyle(fontSize: 11, color: AC.muted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onCopy(url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AC.light.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AC.light.withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 11, color: AC.light),
                      SizedBox(width: 4),
                      Text('링크 복사', style: TextStyle(fontSize: 11, color: AC.light, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

// ─── 예배노트 시트 ────────────────────────────────────────────

class _NoteSheet extends StatefulWidget {
  final ChurchContentRepository repo;
  const _NoteSheet({required this.repo});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notes = await widget.repo.getWorshipNotes();
      if (mounted) setState(() { _notes = notes; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _notes = []; _loading = false; });
    }
  }

  void _showWrite(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NoteWriteSheet(
        repo: widget.repo,
        onSaved: () { _load(); Navigator.pop(ctx); },
      ),
    );
  }

  Future<void> _delete(String id) async {
    await widget.repo.deleteWorshipNote(id);
    _load();
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
                  const Text('예배노트',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showWrite(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AC.light.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AC.light.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: AC.light),
                          SizedBox(width: 5),
                          Text('작성', style: TextStyle(fontSize: 12, color: AC.light, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? const Center(
                          child: Text('작성된 노트가 없어요\n작성 버튼으로 은혜를 기록해보세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AC.muted, fontSize: 13, height: 1.5)),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _notes.length,
                          itemBuilder: (_, i) {
                            final note = _notes[i];
                            final date = (note['created_at'] as String?)?.substring(0, 10) ?? '';
                            final content = note['content'] as String? ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                              decoration: BoxDecoration(
                                color: const Color(0xCC14102A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AC.light.withOpacity(0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.edit_note_rounded, size: 13, color: AC.light),
                                      const SizedBox(width: 5),
                                      Text(date, style: const TextStyle(fontSize: 11, color: AC.muted)),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _delete(note['id'] as String),
                                        child: const Icon(Icons.delete_outline_rounded, size: 16, color: AC.muted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(content,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFE9E4FF), height: 1.6)),
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

// ─── 예배노트 작성 시트 ───────────────────────────────────────

class _NoteWriteSheet extends StatefulWidget {
  final ChurchContentRepository repo;
  final VoidCallback onSaved;
  const _NoteWriteSheet({required this.repo, required this.onSaved});

  @override
  State<_NoteWriteSheet> createState() => _NoteWriteSheetState();
}

class _NoteWriteSheetState extends State<_NoteWriteSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _ctrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.repo.saveWorshipNote(content);
      widget.onSaved();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
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
            const Text('예배노트 작성',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 7,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                decoration: const InputDecoration(
                  hintText: '오늘 예배 중 받은 은혜를 기록해보세요...',
                  hintStyle: TextStyle(color: AC.muted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
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
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0CF), Color(0xFFFFC55E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1030)))
                    : const Text('저장',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1030))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
