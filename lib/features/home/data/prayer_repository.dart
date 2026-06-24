import 'package:supabase_flutter/supabase_flutter.dart';

class PrayerRepository {
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

  Future<List<Map<String, dynamic>>> getMyPrayers() async {
    return await _client
        .from('prayer_requests')
        .select()
        .eq('author_id', _uid)
        .order('created_at', ascending: false);
  }

  Future<void> leavePrayer(String id) async {
    await _client
        .from('prayer_requests')
        .update({'is_left': true})
        .eq('id', id)
        .eq('author_id', _uid);
  }

  Future<List<Map<String, dynamic>>> getLeftPrayers() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];

    // 내가 이미 담은 기도 ID 목록
    final savedRows = await _client
        .from('saved_prayers')
        .select('prayer_request_id')
        .eq('user_id', _uid);
    final savedIds = savedRows.map((r) => r['prayer_request_id'] as String).toSet();

    final prayers = await _client
        .from('prayer_requests')
        .select()
        .eq('church_id', churchId)
        .eq('is_left', true)
        .order('created_at', ascending: false);

    // 내가 이미 담은 것은 제외
    final filtered = prayers.where((p) => !savedIds.contains(p['id'] as String)).toList();
    if (filtered.isEmpty) return [];

    final authorIds = filtered.map((p) => p['author_id'] as String).toSet().toList();
    final users = await _client
        .from('users')
        .select('id, nickname')
        .inFilter('id', authorIds);
    final nicknames = {
      for (final u in users) u['id'] as String: u['nickname'] as String? ?? '알 수 없음'
    };
    return filtered.map((p) => {
      ...p,
      '_author_nickname': nicknames[p['author_id'] as String] ?? '알 수 없음',
    }).toList();
  }

  Future<void> createPrayer({
    required String content,
    String visibility = 'public',
    String? partnerGroupId,
  }) async {
    final churchId = await _getChurchId();
    await _client.from('prayer_requests').insert({
      'author_id': _uid,
      'church_id': churchId,
      'content': content,
      'visibility': visibility,
      if (partnerGroupId != null) 'partner_group_id': partnerGroupId,
    });
  }

  Future<List<Map<String, dynamic>>> getPartnerPrayers() async {
    try {
      final memberRows = await _client
          .from('prayer_partner_members')
          .select('partner_group_id')
          .eq('user_id', _uid)
          .eq('status', 'accepted');
      if (memberRows.isEmpty) return [];
      final groupIds = memberRows.map((r) => r['partner_group_id'] as String).toList();
      return await _client
          .from('prayer_requests')
          .select()
          .eq('visibility', 'partner')
          .inFilter('partner_group_id', groupIds)
          .neq('author_id', _uid)
          .order('created_at', ascending: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> updatePrayer(
    String id, {
    required String content,
    required String visibility,
  }) async {
    await _client
        .from('prayer_requests')
        .update({'content': content, 'visibility': visibility})
        .eq('id', id)
        .eq('author_id', _uid);
  }

  Future<void> deletePrayer(String id) async {
    await _client
        .from('prayer_requests')
        .delete()
        .eq('id', id)
        .eq('author_id', _uid);
  }

  // 담아둔 기도제목
  Future<List<Map<String, dynamic>>> getSavedPrayers() async {
    final rows = await _client
        .from('saved_prayers')
        .select('*, prayer_requests(*)')
        .eq('user_id', _uid)
        .order('saved_at', ascending: false);
    return rows;
  }

  Future<void> savePrayer(String prayerId) async {
    await _client.from('saved_prayers').insert({
      'user_id': _uid,
      'prayer_request_id': prayerId,
    });
  }

  Future<void> unsavePrayer(String prayerId) async {
    await _client
        .from('saved_prayers')
        .delete()
        .eq('user_id', _uid)
        .eq('prayer_request_id', prayerId);
  }

  Future<int> getPrayCount(String prayerId) async {
    final res = await _client
        .from('prayer_together')
        .select()
        .eq('prayer_request_id', prayerId);
    return (res as List).length;
  }

  Future<bool> isAlreadyPraying(String prayerId) async {
    final res = await _client
        .from('prayer_together')
        .select()
        .eq('prayer_request_id', prayerId)
        .eq('user_id', _uid)
        .maybeSingle();
    return res != null;
  }

  Future<void> prayForPrayer(String prayerId) async {
    await _client.from('prayer_together').insert({
      'prayer_request_id': prayerId,
      'user_id': _uid,
    });
  }

  Future<void> unprayForPrayer(String prayerId) async {
    await _client
        .from('prayer_together')
        .delete()
        .eq('prayer_request_id', prayerId)
        .eq('user_id', _uid);
  }

  Future<Map<String, dynamic>> getPrayerTogetherInfo(String prayerId) async {
    try {
      final rows = await _client
          .from('prayer_together')
          .select('user_id')
          .eq('prayer_request_id', prayerId);
      if (rows.isEmpty) return {'count': 0, 'nicknames': <String>[]};
      final userIds = rows.map((r) => r['user_id'] as String).toSet().toList();
      final users = await _client
          .from('users')
          .select('id, nickname')
          .inFilter('id', userIds);
      final nicknames = users.map((u) => u['nickname'] as String? ?? '알 수 없음').toList();
      return {'count': rows.length, 'nicknames': nicknames};
    } catch (_) {
      return {'count': 0, 'nicknames': <String>[]};
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyRanking() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final rows = await _client
        .from('prayer_together')
        .select('user_id')
        .gte('prayed_at', weekAgo);

    if (rows.isEmpty) return [];

    final userIds = rows.map((r) => r['user_id'] as String).toSet().toList();
    final users = await _client
        .from('users')
        .select('id, nickname')
        .inFilter('id', userIds);
    final nicknames = {
      for (final u in users) u['id'] as String: u['nickname'] as String? ?? '알 수 없음'
    };

    final Map<String, int> counts = {};
    for (final row in rows) {
      final uid = row['user_id'] as String;
      counts[uid] = (counts[uid] ?? 0) + 1;
    }

    final result = counts.entries
        .map((e) => {'nickname': nicknames[e.key] ?? '알 수 없음', 'count': e.value})
        .toList();
    result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return result;
  }
}
