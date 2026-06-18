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
import 'widgets/room_nav.dart';

class WorshipHallPage extends StatefulWidget {
  const WorshipHallPage({super.key});

  @override
  State<WorshipHallPage> createState() => _WorshipHallPageState();
}

class _WorshipHallPageState extends State<WorshipHallPage> {
  double _selfX = 50, _selfY = 72;
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
    final worships = await _repo.getWeeklyWorship();
    if (mounted) setState(() { _worships = worships; _loading = false; });

    await _presence.join(nickname: _myNickname, x: _selfX, y: _selfY, room: 'worship');
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
      backgroundColor: AC.bgBot,
      bottomNavigationBar: const RoomNavBar(current: RoomType.worship),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _onTapBackground(d, constraints),
              child: Stack(
                children: [
                  const Positioned.fill(child: WorshipScene()),
                  // 주보/다시보기 카드 영역
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: constraints.maxHeight * 0.42,
                    child: _buildWorshipBoard(constraints),
                  ),
                  for (var i = 0; i < _onlineUsers.length; i++)
                    _buildUserAvatar(_onlineUsers[i], constraints, i),
                  _buildSelfAvatar(constraints),
                  Positioned(
                    left: 0, right: 0,
                    bottom: constraints.maxHeight * 0.13,
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
    );
  }

  Widget _buildWorshipBoard(BoxConstraints constraints) {
    final topPad = MediaQuery.of(context).padding.top + constraints.maxHeight * 0.09;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPad),
        Padding(
          padding: const EdgeInsets.only(left: 18, bottom: 10),
          child: const Text('주보 & 예배 다시보기',
              style: TextStyle(fontSize: 11, color: AC.muted, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _worships.isEmpty
                  ? const Center(
                      child: Text('등록된 주보가 없어요',
                          style: TextStyle(color: AC.muted, fontSize: 13)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _worships.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _WorshipCard(worship: _worships[i]),
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
}

class _WorshipCard extends StatelessWidget {
  final Map<String, dynamic> worship;
  const _WorshipCard({required this.worship});

  @override
  Widget build(BuildContext context) {
    final title = worship['title'] as String? ?? '';
    final date = worship['date'] as String? ?? '';
    final bulletinUrl = worship['bulletin_url'] as String?;
    final replayUrl = worship['replay_url'] as String?;

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xCC14102A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.light.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: AC.light.withOpacity(0.1), blurRadius: 14)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주보 이미지
          Expanded(
            child: bulletinUrl != null
                ? GestureDetector(
                    onTap: () => _showFullImage(context, bulletinUrl),
                    child: Image.network(
                      bulletinUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                if (date.length >= 10)
                  Text(date.substring(0, 10),
                      style: const TextStyle(fontSize: 10, color: AC.muted)),
                if (replayUrl != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: replayUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('링크가 복사됐어요'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AC.light.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AC.light.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline_rounded, size: 11, color: AC.light),
                          SizedBox(width: 4),
                          Text('다시보기 링크 복사',
                              style: TextStyle(fontSize: 10, color: AC.light, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Center(child: Icon(Icons.image_rounded, size: 32, color: AC.muted)),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(
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
    );
  }
}
