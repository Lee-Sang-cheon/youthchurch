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

  Future<void> createPrayer({
    required String content,
    String visibility = 'private',
  }) async {
    final churchId = await _getChurchId();
    await _client.from('prayer_requests').insert({
      'author_id': _uid,
      'church_id': churchId,
      'content': content,
      'visibility': visibility,
    });
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
}
