import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/church_content_repository.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _repo = ChurchContentRepository();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getScheduleEvents();
      if (mounted) setState(() => _events = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 날짜별 그룹핑
  Map<String, List<Map<String, dynamic>>> _groupByMonth() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in _events) {
      final date = e['date'] as String? ?? '';
      if (date.length < 7) continue;
      final key = date.substring(0, 7); // "2025-06"
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  String _formatMonth(String key) {
    final parts = key.split('-');
    if (parts.length < 2) return key;
    return '${parts[0]}년 ${int.parse(parts[1])}월';
  }

  String _formatDate(String date) {
    if (date.length < 10) return date;
    final parts = date.split('-');
    if (parts.length < 3) return date;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    try {
      final dt = DateTime.parse(date);
      return '${int.parse(parts[1])}/${int.parse(parts[2])} (${weekdays[dt.weekday - 1]})';
    } catch (_) {
      return '${int.parse(parts[1])}/${int.parse(parts[2])}';
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'WORSHIP': return AC.light;
      case 'MEETING': return AC.glass1;
      case 'EVENT': return AC.glass2;
      case 'HOLIDAY': return AC.live;
      default: return AC.muted;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'WORSHIP': return '예배';
      case 'MEETING': return '모임';
      case 'EVENT': return '행사';
      case 'HOLIDAY': return '공휴일';
      case 'BIRTHDAY': return '생일';
      default: return '일정';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bgBot,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AC.bgTop, AC.bgBot],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('일정',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _events.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 44, color: AC.muted),
                                SizedBox(height: 12),
                                Text('등록된 일정이 없어요',
                                    style: TextStyle(
                                        color: AC.muted, fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: _buildList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final grouped = _groupByMonth();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
            child: Text(_formatMonth(entry.key),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AC.muted)),
          ),
          for (final e in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Glass(
                radius: 14,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _typeColor(e['type'] as String?),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['title'] as String,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(_formatDate(e['date'] as String? ?? ''),
                                  style: const TextStyle(
                                      fontSize: 12, color: AC.muted)),
                              if (e['time'] != null) ...[
                                const Text(' · ',
                                    style: TextStyle(
                                        fontSize: 12, color: AC.muted)),
                                Text(
                                    (e['time'] as String)
                                        .substring(0, 5),
                                    style: const TextStyle(
                                        fontSize: 12, color: AC.muted)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _typeColor(e['type'] as String?)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel(e['type'] as String?),
                        style: TextStyle(
                            fontSize: 10,
                            color: _typeColor(e['type'] as String?),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
