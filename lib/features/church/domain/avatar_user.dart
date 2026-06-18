import 'package:flutter/material.dart';

class AvatarUser {
  final int id;
  final String uid;
  final String name;
  final String role;
  final String status;
  final String? prayer;
  final Color color;
  final Color color2;
  final double x;
  final double y;
  final double scale;
  final bool live;

  const AvatarUser({
    required this.id,
    this.uid = '',
    required this.name,
    required this.role,
    required this.status,
    this.prayer,
    required this.color,
    required this.color2,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.live = false,
  });

  AvatarUser copyWith({double? x, double? y, double? scale, String? prayer}) => AvatarUser(
        id: id,
        uid: uid,
        name: name,
        role: role,
        status: status,
        prayer: prayer ?? this.prayer,
        color: color,
        color2: color2,
        x: x ?? this.x,
        y: y ?? this.y,
        scale: scale ?? this.scale,
        live: live,
      );
}

const List<AvatarUser> kSampleUsers = [
  AvatarUser(id: 1, name: '지수', role: '찬양팀', status: '오늘 콘티 미쳤다', color: Color(0xFF7C5CFF), color2: Color(0xFFC5B6FF), x: 28, y: 58, scale: 0.78),
  AvatarUser(id: 2, name: '도윤', role: '3년차', status: '예배 5분 전', color: Color(0xFF3BD6C6), color2: Color(0xFFBDFFF4), x: 65, y: 54, scale: 0.74),
  AvatarUser(id: 3, name: '서연', role: '새가족', status: '처음 왔어요', color: Color(0xFFFF7EB6), color2: Color(0xFFFFD2E7), x: 48, y: 46, scale: 1.0),
  AvatarUser(id: 4, name: '민재', role: '리더', status: '셀모임 8시!', color: Color(0xFFFFA14D), color2: Color(0xFFFFE0B8), x: 18, y: 48, scale: 1.04),
  AvatarUser(id: 5, name: '하은', role: '미디어팀', status: '라이브 송출 중', color: Color(0xFF5B9DFF), color2: Color(0xFFCFE2FF), x: 80, y: 44, scale: 0.96, live: true),
  AvatarUser(id: 6, name: '예준', role: '2년차', status: '큐티 나눔 구해요', color: Color(0xFF9D8CFF), color2: Color(0xFFDDD5FF), x: 88, y: 66, scale: 0.66),
  AvatarUser(id: 7, name: '수아', role: '찬양팀', status: '사운드체크 중', color: Color(0xFFFF9BB0), color2: Color(0xFFFFE2E9), x: 10, y: 64, scale: 0.68),
];
