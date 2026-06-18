import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/challenge_repository.dart';

class ChallengeTab extends StatefulWidget {
  const ChallengeTab({super.key});

  @override
  State<ChallengeTab> createState() => _ChallengeTabState();
}

class _ChallengeTabState extends State<ChallengeTab> {
  final _repo = ChallengeRepository();
  List<Map<String, dynamic>> _joined = [];
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getMyJoinedChallenges(),
        _repo.getChurchChallenges(),
      ]);
      if (mounted) {
        setState(() {
          _joined = results[0];
          _all = results[1];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateChallenge() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int totalDays = 21;
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
                const Text('챌린지 만들기',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '챌린지 이름 (예: 미라클모닝 21일)',
                    hintStyle: const TextStyle(color: AC.muted),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '설명 (선택)',
                    hintStyle: const TextStyle(color: AC.muted),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('목표 일수',
                        style: TextStyle(color: AC.muted, fontSize: 13)),
                    const SizedBox(width: 12),
                    for (final d in [7, 21, 40, 66])
                      GestureDetector(
                        onTap: () => setS(() => totalDays = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: totalDays == d
                                ? AC.glass1.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                                color: totalDays == d
                                    ? AC.glass1
                                    : Colors.white24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$d일',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: totalDays == d
                                      ? AC.glass1
                                      : AC.muted)),
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
                      if (titleCtrl.text.trim().isEmpty) return;
                      await _repo.createChallenge(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        totalDays: totalDays,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AC.glass1,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('만들기',
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
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChallenge,
        backgroundColor: AC.glass1,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  if (_joined.isNotEmpty) ...[
                    const _SectionHeader(title: '참여 중'),
                    const SizedBox(height: 8),
                    for (final c in _joined)
                      _JoinedChallengeCard(
                        challenge: c,
                        repo: _repo,
                        onRefresh: _load,
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (_all.isNotEmpty) ...[
                    const _SectionHeader(title: '교회 챌린지'),
                    const SizedBox(height: 8),
                    for (final c in _all)
                      _ChallengeCard(
                        challenge: c,
                        joined: _joined.any((j) => j['id'] == c['id']),
                        onJoin: () async {
                          await _repo.joinChallenge(c['id'] as String);
                          _load();
                        },
                      ),
                  ],
                  if (_all.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 44, color: AC.muted),
                            SizedBox(height: 12),
                            Text('아직 챌린지가 없어요',
                                style: TextStyle(
                                    color: AC.muted, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('+ 버튼으로 챌린지를 만들어 보세요',
                                style: TextStyle(
                                    color: AC.muted, fontSize: 12)),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AC.muted,
            letterSpacing: 0.5));
  }
}

class _JoinedChallengeCard extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final ChallengeRepository repo;
  final VoidCallback onRefresh;
  const _JoinedChallengeCard(
      {required this.challenge, required this.repo, required this.onRefresh});

  @override
  State<_JoinedChallengeCard> createState() => _JoinedChallengeCardState();
}

class _JoinedChallengeCardState extends State<_JoinedChallengeCard> {
  int _done = 0;
  bool _checkedToday = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final id = widget.challenge['id'] as String;
    final results = await Future.wait([
      widget.repo.getMyRecords(id),
      widget.repo.isCheckedInToday(id),
    ]);
    if (mounted) {
      setState(() {
        _done = (results[0] as List).length;
        _checkedToday = results[1] as bool;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final total = (c['total_days'] as int?) ?? 21;
    final progress = total > 0 ? _done / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c['title'] as String,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                Text('$_done / $total일',
                    style:
                        const TextStyle(fontSize: 12, color: AC.muted)),
              ],
            ),
            if (c['description'] != null) ...[
              const SizedBox(height: 4),
              Text(c['description'] as String,
                  style: const TextStyle(fontSize: 12, color: AC.muted)),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _loading ? null : progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AC.glass1),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: (_checkedToday || _loading)
                    ? null
                    : () async {
                        await widget.repo
                            .checkIn(c['id'] as String);
                        await _loadProgress();
                        widget.onRefresh();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AC.glass1,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _checkedToday ? '오늘 완료!' : '오늘 체크인',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool joined;
  final VoidCallback onJoin;
  const _ChallengeCard(
      {required this.challenge,
      required this.joined,
      required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final total = (c['total_days'] as int?) ?? 21;
    final participants =
        (c['participants'] as List?)?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['title'] as String,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('$total일 · $participants명 참여',
                      style: const TextStyle(
                          fontSize: 11, color: AC.muted)),
                  if (c['description'] != null) ...[
                    const SizedBox(height: 2),
                    Text(c['description'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: AC.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            joined
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AC.glass1.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AC.glass1.withOpacity(0.4)),
                    ),
                    child: const Text('참여 중',
                        style: TextStyle(
                            fontSize: 11,
                            color: AC.glass1,
                            fontWeight: FontWeight.w600)),
                  )
                : GestureDetector(
                    onTap: onJoin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AC.light.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AC.light.withOpacity(0.5)),
                      ),
                      child: const Text('참여',
                          style: TextStyle(
                              fontSize: 11,
                              color: AC.light,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
