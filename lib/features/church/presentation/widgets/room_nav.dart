import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../prayer_room_page.dart';
import '../worship_hall_page.dart';
import '../small_group_room_page.dart';

enum RoomType { prayer, smallGroup, worship }

class RoomNavBar extends StatelessWidget {
  final RoomType current;
  const RoomNavBar({super.key, required this.current});

  static const _items = [
    (RoomType.prayer, Icons.self_improvement_rounded, '기도실'),
    (RoomType.smallGroup, Icons.groups_rounded, '소그룹'),
    (RoomType.worship, Icons.church_rounded, '예배당'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
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
                children: _items.map((item) {
                  final (type, icon, label) = item;
                  final selected = type == current;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onTap(context, type),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 22,
                            color: selected ? AC.light : Colors.white.withOpacity(0.35),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
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
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, RoomType to) {
    if (to == current) return;
    if (to == RoomType.prayer) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PrayerRoomPage()),
      );
    } else if (to == RoomType.worship) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorshipHallPage()),
      );
    } else {
      _showGroupPicker(context);
    }
  }

  void _showGroupPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _GroupPickerSheet(),
    );
  }
}

// ── 소그룹 선택 시트 ─────────────────────────────────────────────────────────

class _GroupPickerSheet extends StatefulWidget {
  const _GroupPickerSheet();

  @override
  State<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends State<_GroupPickerSheet> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
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
            const Text(
              '소그룹',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
            else if (_groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.group_off_rounded, color: AC.muted, size: 40),
                    SizedBox(height: 10),
                    Text('소속된 소그룹이 없습니다', style: TextStyle(color: AC.muted, fontSize: 14)),
                  ],
                ),
              )
            else
              ...(_groups.map((g) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SmallGroupRoomPage(
                            cellGroupId: g['id'] as String,
                            groupName: g['name'] as String? ?? '',
                          ),
                        ),
                      );
                    },
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
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
