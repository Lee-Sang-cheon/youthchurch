import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _client = Supabase.instance.client;
  String? _nickname;
  String? _churchName;
  int _prayerCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final user = await _client.from('users').select('nickname, church_id').eq('id', uid).maybeSingle();
    final churchId = user?['church_id'] as String?;
    String? churchName;
    if (churchId != null) {
      final church = await _client.from('churches').select('name').eq('id', churchId).maybeSingle();
      churchName = church?['name'] as String?;
    }
    final prayers = await _client.from('prayer_requests').select('id').eq('author_id', uid);
    if (mounted) {
      setState(() {
        _nickname = user?['nickname'] as String?;
        _churchName = churchName;
        _prayerCount = prayers.length;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AC.bgMid,
        title: const Text('로그아웃', style: TextStyle(color: Colors.white)),
        content: const Text('로그아웃 하시겠어요?', style: TextStyle(color: AC.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _client.auth.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                          const SizedBox(width: 12),
                          const Text('마이페이지', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 프로필
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AC.light.withOpacity(0.15),
                        border: Border.all(color: AC.light.withOpacity(0.4), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _nickname?.isNotEmpty == true ? _nickname![0] : '?',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AC.light),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nickname ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    if (_churchName != null) ...[
                      const SizedBox(height: 4),
                      Text(_churchName!, style: const TextStyle(fontSize: 13, color: AC.muted)),
                    ],
                    const SizedBox(height: 28),
                    // 스탯
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Glass(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(label: '기도제목', value: '$_prayerCount'),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[300],
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AC.light)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AC.muted)),
      ],
    );
  }
}
