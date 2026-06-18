import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/prayer_repository.dart';
import 'challenge_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _repo = PrayerRepository();
  List<Map<String, dynamic>> _prayers = [];
  List<Map<String, dynamic>> _savedPrayers = [];
  bool _loading = true;
  // 기도제목 탭 내 필터: 0=내 기도제목, 1=담아둔 기도제목
  int _prayerFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getMyPrayers(),
        _repo.getSavedPrayers(),
      ]);
      if (mounted) {
        setState(() {
          _prayers = results[0];
          _savedPrayers = results[1];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddPrayer() {
    final ctrl = TextEditingController();
    String visibility = 'private';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              14, 0, 14, MediaQuery.of(ctx).viewInsets.bottom + 40),
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '기도제목 추가',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '기도제목을 입력하세요',
                    hintStyle: const TextStyle(color: AC.muted),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('공개 범위',
                        style: TextStyle(color: AC.muted, fontSize: 13)),
                    const SizedBox(width: 12),
                    for (final v in ['private', 'public'])
                      GestureDetector(
                        onTap: () => setS(() => visibility = v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: visibility == v
                                ? AC.light.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: visibility == v
                                  ? AC.light
                                  : Colors.white24,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            v == 'private' ? '나만 보기' : '교회 공개',
                            style: TextStyle(
                              fontSize: 12,
                              color: visibility == v ? AC.light : AC.muted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (ctrl.text.trim().isEmpty) return;
                      await _repo.createPrayer(
                        content: ctrl.text.trim(),
                        visibility: visibility,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadAll();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AC.light,
                      foregroundColor: AC.bgBot,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('저장',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
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
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AC.bgTop, AC.bgBot],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildPrayerTab(),
                      const ChallengeTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (_tab.index == 0 && _prayerFilter == 0)
          ? FloatingActionButton(
              onPressed: _showAddPrayer,
              backgroundColor: AC.light,
              foregroundColor: AC.bgBot,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            '내 공간',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(
            color: AC.light.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AC.light.withOpacity(0.5)),
          ),
          labelColor: AC.light,
          unselectedLabelColor: AC.muted,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '기도제목'),
            Tab(text: '챌린지'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTab() {
    return Column(
      children: [
        // 필터 칩
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              for (final entry in {0: '내 기도제목', 1: '담아둔 기도제목'}.entries)
                GestureDetector(
                  onTap: () => setState(() => _prayerFilter = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _prayerFilter == entry.key
                          ? AC.light.withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: _prayerFilter == entry.key
                            ? AC.light
                            : Colors.white24,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _prayerFilter == entry.key ? AC.light : AC.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _prayerFilter == 0
                  ? _buildMyPrayers()
                  : _buildSavedPrayers(),
        ),
      ],
    );
  }

  Widget _buildMyPrayers() {
    if (_prayers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.self_improvement_rounded, size: 48, color: AC.muted),
            SizedBox(height: 12),
            Text('기도제목을 추가해보세요', style: TextStyle(color: AC.muted, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _prayers.length,
        itemBuilder: (_, i) => _PrayerCard(
          prayer: _prayers[i],
          onDelete: () async {
            await _repo.deletePrayer(_prayers[i]['id'] as String);
            _loadAll();
          },
        ),
      ),
    );
  }

  Widget _buildSavedPrayers() {
    if (_savedPrayers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 48, color: AC.muted),
            SizedBox(height: 12),
            Text('담아둔 기도제목이 없어요', style: TextStyle(color: AC.muted, fontSize: 14)),
            SizedBox(height: 4),
            Text('교회에서 다른 사람의 기도제목을 담아보세요',
                style: TextStyle(color: AC.muted, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _savedPrayers.length,
        itemBuilder: (_, i) {
          final pr = _savedPrayers[i]['prayer_requests'] as Map<String, dynamic>?;
          if (pr == null) return const SizedBox.shrink();
          return _PrayerCard(
            prayer: pr,
            isSaved: true,
            onDelete: () async {
              await _repo.unsavePrayer(pr['id'] as String);
              _loadAll();
            },
          );
        },
      ),
    );
  }

  Widget _buildComingSoon(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock_rounded, size: 40, color: AC.muted),
          const SizedBox(height: 12),
          Text('$label 기능은 곧 오픈돼요',
              style: const TextStyle(color: AC.muted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final Map<String, dynamic> prayer;
  final VoidCallback onDelete;
  final bool isSaved;
  const _PrayerCard({required this.prayer, required this.onDelete, this.isSaved = false});

  @override
  Widget build(BuildContext context) {
    final visibility = prayer['visibility'] as String? ?? 'private';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer['content'] as String,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: visibility == 'public'
                          ? AC.glass2.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: visibility == 'public'
                            ? AC.glass2.withOpacity(0.5)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      visibility == 'public' ? '교회 공개' : '나만 보기',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            visibility == 'public' ? AC.glass2 : AC.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark_remove_outlined : Icons.delete_outline_rounded,
                size: 20,
                color: AC.muted,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
