import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';

class ChurchSetupPage extends StatefulWidget {
  final VoidCallback onComplete;
  const ChurchSetupPage({super.key, required this.onComplete});

  @override
  State<ChurchSetupPage> createState() => _ChurchSetupPageState();
}

class _ChurchSetupPageState extends State<ChurchSetupPage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _showCreate = false;
  final _client = Supabase.instance.client;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final church = await _client
          .from('churches')
          .select()
          .eq('invite_code', code)
          .maybeSingle();
      if (church == null) {
        _showError('유효하지 않은 초대 코드예요');
        return;
      }
      await _updateUserChurch(church['id'] as String);
    } catch (e) {
      _showError('오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createChurch() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      String code;
      // 코드 중복 확인 후 고유 코드 생성
      while (true) {
        code = _generateInviteCode();
        final existing = await _client
            .from('churches')
            .select('id')
            .eq('invite_code', code)
            .maybeSingle();
        if (existing == null) break;
      }
      final church = await _client
          .from('churches')
          .insert({'name': name, 'invite_code': code})
          .select()
          .single();
      await _updateUserChurch(church['id'] as String);
      if (mounted) _showCreatedDialog(name, code);
    } catch (e) {
      _showError('오류: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserChurch(String churchId) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('users').update({'church_id': churchId}).eq('id', uid);
  }

  void _showCreatedDialog(String name, String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _InviteCodeSheet(
        churchName: name,
        code: code,
        onConfirm: widget.onComplete,
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[400]),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // 아이콘
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AC.light.withOpacity(0.12),
                      border: Border.all(color: AC.light.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.church_rounded, color: AC.light, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '소속된 교회 공동체가 없습니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '초대 코드를 입력하거나 새 공동체를 만들어보세요',
                    style: TextStyle(fontSize: 13, color: AC.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // 코드 입력
                  Glass(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: '초대 코드 입력',
                        hintStyle: TextStyle(
                          color: AC.muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _joinByCode(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _joinByCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AC.light,
                        foregroundColor: AC.bgBot,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '코드로 참여하기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  // 구분선
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('또는', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: Colors.white12)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 교회 생성
                  if (!_showCreate) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showCreate = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '교회 공동체 생성하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ] else ...[
                    Glass(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '예) 주사랑교회 청년부',
                          hintStyle: TextStyle(color: AC.muted),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _createChurch(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createChurch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AC.glass1,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                '공동체 만들기',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showCreate = false),
                      child: const Text('취소', style: TextStyle(color: AC.muted)),
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 공동체 생성 완료 + 초대코드 공유 시트
class _InviteCodeSheet extends StatelessWidget {
  final String churchName;
  final String code;
  final VoidCallback onConfirm;
  const _InviteCodeSheet({required this.churchName, required this.code, required this.onConfirm});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드가 복사됐어요'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AC.online, size: 48),
            const SizedBox(height: 12),
            Text(
              churchName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text('공동체가 생성됐어요!', style: TextStyle(fontSize: 14, color: AC.muted)),
            const SizedBox(height: 24),
            const Text('초대 코드', style: TextStyle(fontSize: 12, color: AC.muted)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _copyCode(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AC.light.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AC.light.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AC.light,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.copy_rounded, color: AC.light, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('탭하면 복사됩니다', style: TextStyle(fontSize: 11, color: AC.muted)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AC.light,
                  foregroundColor: AC.bgBot,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('시작하기', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 기존 교회 멤버용 초대 코드 공유 시트 (ChurchHallPage에서 호출)
class ChurchInviteSheet extends StatefulWidget {
  const ChurchInviteSheet({super.key});

  @override
  State<ChurchInviteSheet> createState() => _ChurchInviteSheetState();
}

class _ChurchInviteSheetState extends State<ChurchInviteSheet> {
  String? _churchName;
  String? _code;
  bool _loading = true;
  final _client = Supabase.instance.client;

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
    if (churchId == null) return;
    final church = await _client.from('churches').select('name, invite_code').eq('id', churchId).maybeSingle();
    if (mounted) {
      setState(() {
        _churchName = church?['name'] as String?;
        _code = church?['invite_code'] as String?;
        _loading = false;
      });
    }
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드가 복사됐어요'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: _loading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _churchName ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text('친구를 공동체에 초대해보세요', style: TextStyle(fontSize: 13, color: AC.muted)),
                  const SizedBox(height: 24),
                  const Text('초대 코드', style: TextStyle(fontSize: 12, color: AC.muted)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: AC.light.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AC.light.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _code ?? '',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AC.light,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.copy_rounded, color: AC.light, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('탭하면 복사됩니다', style: TextStyle(fontSize: 11, color: AC.muted)),
                ],
              ),
      ),
    );
  }
}
