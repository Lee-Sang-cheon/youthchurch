import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final res = await _client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return res;
  }

  Future<void> updateNickname(String nickname) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .from('users')
        .upsert({'id': uid, 'nickname': nickname});
  }
}
