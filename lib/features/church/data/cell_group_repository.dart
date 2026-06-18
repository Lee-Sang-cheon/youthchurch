import 'package:supabase_flutter/supabase_flutter.dart';

class CellGroupRepository {
  final _client = Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  Future<String?> _getChurchId() async {
    if (_uid == null) return null;
    final res = await _client
        .from('users')
        .select('church_id')
        .eq('id', _uid!)
        .maybeSingle();
    return res?['church_id'] as String?;
  }

  Future<List<Map<String, dynamic>>> getCellGroups() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];
    return await _client
        .from('cell_groups')
        .select()
        .eq('church_id', churchId)
        .order('name');
  }

  Future<String?> getMyCellGroupId() async {
    if (_uid == null) return null;
    final res = await _client
        .from('cell_group_members')
        .select('cell_group_id')
        .eq('user_id', _uid!)
        .maybeSingle();
    return res?['cell_group_id'] as String?;
  }

  Future<bool> isMember(String cellGroupId) async {
    if (_uid == null) return false;
    final res = await _client
        .from('cell_group_members')
        .select('user_id')
        .eq('cell_group_id', cellGroupId)
        .eq('user_id', _uid!)
        .maybeSingle();
    return res != null;
  }

  Future<List<Map<String, dynamic>>> getMembers(String cellGroupId) async {
    final members = await _client
        .from('cell_group_members')
        .select('user_id')
        .eq('cell_group_id', cellGroupId);

    final userIds = (members as List).map((m) => m['user_id'] as String).toList();
    if (userIds.isEmpty) return [];

    return await _client
        .from('users')
        .select('id, nickname')
        .inFilter('id', userIds);
  }

  Future<List<Map<String, dynamic>>> getNotices(String cellGroupId) async {
    return await _client
        .from('cell_notices')
        .select()
        .eq('cell_group_id', cellGroupId)
        .order('created_at', ascending: false);
  }

  Future<void> addNotice(String cellGroupId, String content) async {
    await _client.from('cell_notices').insert({
      'cell_group_id': cellGroupId,
      'content': content,
      'author_id': _uid,
    });
  }

  Future<List<Map<String, dynamic>>> getSharing(String cellGroupId) async {
    return await _client
        .from('cell_sharing')
        .select()
        .eq('cell_group_id', cellGroupId)
        .order('created_at', ascending: false);
  }

  Future<void> addSharing(String cellGroupId, String title, String content) async {
    await _client.from('cell_sharing').insert({
      'cell_group_id': cellGroupId,
      'title': title,
      'content': content,
      'author_id': _uid,
    });
  }

  Future<void> joinGroup(String cellGroupId) async {
    if (_uid == null) return;
    await _client.from('cell_group_members').upsert({
      'cell_group_id': cellGroupId,
      'user_id': _uid,
    });
  }
}
