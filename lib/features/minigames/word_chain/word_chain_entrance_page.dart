import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import 'word_chain_notifier.dart';
import 'word_chain_lobby_page.dart';

class WordChainEntrancePage extends ConsumerStatefulWidget {
  const WordChainEntrancePage({super.key});

  @override
  ConsumerState<WordChainEntrancePage> createState() =>
      _WordChainEntrancePageState();
}

class _WordChainEntrancePageState extends ConsumerState<WordChainEntrancePage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    await ref.read(wordChainProvider.notifier).createRoom();
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const WordChainLobbyPage()));
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) return;
    setState(() => _loading = true);
    await ref.read(wordChainProvider.notifier).joinRoom(code);
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const WordChainLobbyPage()));
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
                  const Text('끝말잇기',
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
                        color: AC.glass2.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AC.glass2.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded,
                          color: AC.glass2, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('끝말잇기',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text(
                        '앞 사람의 마지막 글자로 시작하는 단어를 대세요!\n틀리면 탈락!',
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
                          backgroundColor: AC.glass2,
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
                                color: AC.glass2.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AC.glass2.withOpacity(0.5)),
                              ),
                              child: const Text('참가',
                                  style: TextStyle(
                                      color: AC.glass2,
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
