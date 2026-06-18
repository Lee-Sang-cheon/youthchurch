import 'package:flutter/material.dart';

/// 공간 안의 한 명의 유저(아바타).
/// x, y 는 화면 대비 백분율 좌표(왼쪽 기준 x%, 바닥 기준 y%).
class AvatarUser {
  final int id;
  final String name;
  final String role;
  final String status;
  final Color color;
  final Color color2;
  final double x;
  final double y;
  final double scale;
  final bool live;

  const AvatarUser({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.color,
    required this.color2,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.live = false,
  });

  AvatarUser copyWith({double? x, double? y, double? scale}) => AvatarUser(
        id: id,
        name: name,
        role: role,
        status: status,
        color: color,
        color2: color2,
        x: x ?? this.x,
        y: y ?? this.y,
        scale: scale ?? this.scale,
        live: live,
      );
}

const List<AvatarUser> kUsers = [
  AvatarUser(id: 1, name: '지수', role: '찬양팀 · 건반', status: '오늘 콘티 미쳤다 🔥', color: Color(0xFF7C5CFF), color2: Color(0xFFC5B6FF), x: 30, y: 25, scale: 0.78),
  AvatarUser(id: 2, name: '도윤', role: '청년부 3년차', status: '예배 5분 전 입장 완료', color: Color(0xFF3BD6C6), color2: Color(0xFFBDFFF4), x: 64, y: 27, scale: 0.74),
  AvatarUser(id: 3, name: '서연', role: '새가족', status: '오늘 처음 왔어요 🙏', color: Color(0xFFFF7EB6), color2: Color(0xFFFFD2E7), x: 47, y: 14, scale: 1.0),
  AvatarUser(id: 4, name: '민재', role: '리더 · 1셀', status: '셀모임 8시 라운지에서!', color: Color(0xFFFFA14D), color2: Color(0xFFFFE0B8), x: 17, y: 13, scale: 1.04),
  AvatarUser(id: 5, name: '하은', role: '미디어팀', status: '오늘 라이브 송출 담당 🎥', color: Color(0xFF5B9DFF), color2: Color(0xFFCFE2FF), x: 80, y: 16, scale: 0.96, live: true),
  AvatarUser(id: 6, name: '예준', role: '청년부 2년차', status: '큐티 나눔 구해요', color: Color(0xFF9D8CFF), color2: Color(0xFFDDD5FF), x: 88, y: 31, scale: 0.66),
  AvatarUser(id: 7, name: '수아', role: '찬양팀 · 보컬', status: '사운드체크 중...', color: Color(0xFFFF9BB0), color2: Color(0xFFFFE2E9), x: 8, y: 30, scale: 0.68),
];

/// 라운지 화면용 재배치.
List<AvatarUser> loungeUsers() {
  final base = kUsers.take(5).toList();
  return [
    for (var i = 0; i < base.length; i++)
      base[i].copyWith(
        x: 18 + i * 16,
        y: 16 + (i % 2) * 8,
        scale: 0.8 + (i % 2) * 0.15,
      ),
  ];
}

enum AppView { hall, worship, lounge }
