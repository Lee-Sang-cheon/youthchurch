import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeRepository {
  final _client = Supabase.instance.client;
  String get _uid => _client.auth.currentUser!.id;

  Future<String?> _getChurchId() async {
    final res = await _client
        .from('users')
        .select('church_id')
        .eq('id', _uid)
        .maybeSingle();
    return res?['church_id'] as String?;
  }

  /// 교회 전체 챌린지
  Future<List<Map<String, dynamic>>> getChurchChallenges() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];
    return await _client
        .from('challenges')
        .select()
        .eq('church_id', churchId)
        .order('created_at', ascending: false);
  }

  /// 내가 참여 중인 챌린지 (participants 배열에 uid 포함)
  Future<List<Map<String, dynamic>>> getMyJoinedChallenges() async {
    final all = await getChurchChallenges();
    return all.where((c) {
      final ps = List<String>.from(c['participants'] as List? ?? []);
      return ps.contains(_uid);
    }).toList();
  }

  /// 챌린지 생성
  Future<void> createChallenge({
    required String title,
    String? description,
    int totalDays = 21,
  }) async {
    final churchId = await _getChurchId();
    await _client.from('challenges').insert({
      'church_id': churchId,
      'author_id': _uid,
      'title': title,
      'description': description,
      'total_days': totalDays,
      'participants': [_uid],
    });
  }

  /// 챌린지 참여
  Future<void> joinChallenge(String challengeId) async {
    final row = await _client
        .from('challenges')
        .select('participants')
        .eq('id', challengeId)
        .single();
    final participants = List<String>.from(row['participants'] as List? ?? []);
    if (!participants.contains(_uid)) {
      participants.add(_uid);
      await _client
          .from('challenges')
          .update({'participants': participants})
          .eq('id', challengeId);
    }
  }

  /// 오늘 체크인 여부
  Future<bool> isCheckedInToday(String challengeId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final rows = await _client
        .from('challenge_records')
        .select()
        .eq('challenge_id', challengeId)
        .eq('member_id', _uid)
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay);
    return rows.isNotEmpty;
  }

  /// 오늘 체크인
  Future<void> checkIn(String challengeId) async {
    final churchId = await _getChurchId();
    final records = await getMyRecords(challengeId);
    final dayNumber = records.length + 1;
    await _client.from('challenge_records').insert({
      'church_id': churchId,
      'challenge_id': challengeId,
      'member_id': _uid,
      'day_number': dayNumber,
    });
  }

  /// 내 진행 기록
  Future<List<Map<String, dynamic>>> getMyRecords(String challengeId) async {
    return await _client
        .from('challenge_records')
        .select()
        .eq('challenge_id', challengeId)
        .eq('member_id', _uid)
        .order('day_number');
  }
}
