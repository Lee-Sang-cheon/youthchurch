import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final user = await _client.from('users').select('church_id').eq('id', uid).maybeSingle();
    final churchId = user?['church_id'] as String?;
    if (churchId == null) { if (mounted) setState(() => _loading = false); return; }
    final members = await _client
        .from('users')
        .select('id, nickname')
        .eq('church_id', churchId)
        .order('nickname');
    if (mounted) setState(() { _members = List<Map<String, dynamic>>.from(members); _loading = false; });
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
                    const Text('구성원', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Spacer(),
                    Text('${_members.length}명', style: const TextStyle(fontSize: 13, color: AC.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _members.isEmpty
                        ? const Center(child: Text('구성원이 없어요', style: TextStyle(color: AC.muted)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final member = _members[i];
                              final nickname = member['nickname'] as String? ?? '이름 없음';
                              final isMe = member['id'] == _client.auth.currentUser?.id;
                              return Glass(
                                radius: 14,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AC.light.withOpacity(0.15),
                                        border: Border.all(color: AC.light.withOpacity(0.3)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          nickname.isNotEmpty ? nickname[0] : '?',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AC.light),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      nickname,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AC.light.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('나', style: TextStyle(fontSize: 10, color: AC.light, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
