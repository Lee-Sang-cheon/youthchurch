import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import 'bible_quiz_models.dart';

class BibleQuizPlayPage extends StatefulWidget {
  const BibleQuizPlayPage({super.key});

  @override
  State<BibleQuizPlayPage> createState() => _BibleQuizPlayPageState();
}

class _BibleQuizPlayPageState extends State<BibleQuizPlayPage> {
  late List<BibleQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedAnswer;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final shuffled = List<BibleQuestion>.from(kBibleQuestions)..shuffle(Random());
    _questions = shuffled.take(5).toList();
  }

  void _selectAnswer(int index) {
    if (_selectedAnswer != null) return;
    setState(() => _selectedAnswer = index);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final correct = _questions[_currentIndex].answerIndex == index;
      setState(() {
        if (correct) _score++;
        if (_currentIndex + 1 >= _questions.length) {
          _finished = true;
        } else {
          _currentIndex++;
          _selectedAnswer = null;
        }
      });
    });
  }

  void _restart() {
    final shuffled = List<BibleQuestion>.from(kBibleQuestions)..shuffle(Random());
    setState(() {
      _questions = shuffled.take(5).toList();
      _currentIndex = 0;
      _selectedAnswer = null;
      _score = 0;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080512),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_finished)
              _buildResult()
            else
              _buildQuestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Glass(
                radius: 999,
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('성경 퀴즈',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              if (!_finished)
                Text('${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(fontSize: 11, color: AC.muted)),
            ],
          ),
          const Spacer(),
          if (!_finished)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AC.light.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AC.light.withOpacity(0.4)),
              ),
              child: Text('점수: $_score',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AC.light)),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 진행 바
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AC.light),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            // 질문
            Glass(
              radius: 16,
              padding: const EdgeInsets.all(20),
              child: Text(q.question,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.5),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            // 선택지
            ...q.choices.asMap().entries.map((entry) {
              final i = entry.key;
              final choice = entry.value;
              final selected = _selectedAnswer == i;
              final correct = q.answerIndex == i;
              final revealed = _selectedAnswer != null;

              Color borderColor = Colors.white12;
              Color bgColor = Colors.white.withOpacity(0.05);
              Color textColor = Colors.white;

              if (revealed) {
                if (correct) {
                  borderColor = Colors.green.withOpacity(0.7);
                  bgColor = Colors.green.withOpacity(0.1);
                  textColor = Colors.green;
                } else if (selected) {
                  borderColor = Colors.red.withOpacity(0.7);
                  bgColor = Colors.red.withOpacity(0.1);
                  textColor = Colors.red;
                }
              } else if (selected) {
                borderColor = AC.light.withOpacity(0.7);
                bgColor = AC.light.withOpacity(0.1);
              }

              return GestureDetector(
                onTap: () => _selectAnswer(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(0x2460 + i),
                            style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(choice,
                            style: TextStyle(
                                fontSize: 15,
                                color: textColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (revealed && correct)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20),
                      if (revealed && selected && !correct)
                        const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 20),
                    ],
                  ),
                ),
              );
            }),
            // 해설
            if (_selectedAnswer != null && q.explanation != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text('📖 ${q.explanation}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.amber, height: 1.4)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final percent = (_score / _questions.length * 100).round();
    String message;
    Color color;
    if (percent >= 80) {
      message = '훌륭해요! 성경 박사!';
      color = Colors.green;
    } else if (percent >= 60) {
      message = '잘했어요! 조금만 더!';
      color = AC.light;
    } else {
      message = '다시 도전해봐요!';
      color = Colors.orange;
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$_score / ${_questions.length}',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('$percent% 정답률',
              style: const TextStyle(fontSize: 14, color: AC.muted)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _restart,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AC.light.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AC.light.withOpacity(0.5)),
                  ),
                  child: const Text('다시 풀기',
                      style: TextStyle(
                          fontSize: 15,
                          color: AC.light,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text('나가기',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
