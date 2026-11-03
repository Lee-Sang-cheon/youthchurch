import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import 'yang_sechan_notifier.dart';
import 'yang_sechan_lobby_page.dart';

class YangSechanEntrancePage extends ConsumerStatefulWidget {
  const YangSechanEntrancePage({super.key});

  @override
  ConsumerState<YangSechanEntrancePage> createState() =>
      _YangSechanEntrancePageState();
}

class _YangSechanEntrancePageState
    extends ConsumerState<YangSechanEntrancePage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    await ref.read(yangSechanProvider.notifier).createRoom();
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const YangSechanLobbyPage()));
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) return;
    setState(() => _loading = true);
    await ref.read(yangSechanProvider.notifier).joinRoom(code);
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const YangSechanLobbyPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Glass(
                      radius: 999,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('양세찬 게임',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AC.glass1.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AC.glass1.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.question_mark_rounded,
                          color: AC.glass1, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('양세찬 게임',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text(
                        '나만 모르는 내 제시어를 맞혀보세요!\n예/아니오 질문으로 정체를 파악하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AC.muted, height: 1.5)),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _create,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AC.glass1,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('방 만들기',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Glass(
                      radius: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w700),
                              maxLength: 6,
                              decoration: const InputDecoration(
                                hintText: '방 코드 입력',
                                hintStyle: TextStyle(
                                    color: AC.muted,
                                    fontSize: 14,
                                    letterSpacing: 1),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _loading ? null : _join,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AC.glass1.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AC.glass1.withOpacity(0.5)),
                              ),
                              child: const Text('참가',
                                  style: TextStyle(
                                      color: AC.glass1,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
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
