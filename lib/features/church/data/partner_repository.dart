import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerRepository {
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

  Future<List<Map<String, dynamic>>> getMyPartnerGroups() async {
    try {
      final memberRows = await _client
          .from('prayer_partner_members')
          .select('partner_group_id')
          .eq('user_id', _uid)
          .eq('status', 'accepted');
      if (memberRows.isEmpty) return [];
      final groupIds = memberRows.map((r) => r['partner_group_id'] as String).toList();
      return await _client
          .from('prayer_partners')
          .select('id, name')
          .inFilter('id', groupIds);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getChurchMembers() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];
    return await _client
        .from('users')
        .select('id, nickname')
        .eq('church_id', churchId)
        .neq('id', _uid);
  }

  Future<String> createPartnerGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final churchId = await _getChurchId();
    final group = await _client
        .from('prayer_partners')
        .insert({'name': name, 'creator_id': _uid, 'church_id': churchId})
        .select()
        .single();
    final groupId = group['id'] as String;

    final members = <Map<String, dynamic>>[
      {'partner_group_id': groupId, 'user_id': _uid, 'invited_by': _uid, 'status': 'accepted'},
      for (final mid in memberIds)
        {'partner_group_id': groupId, 'user_id': mid, 'invited_by': _uid, 'status': 'pending'},
    ];
    await _client.from('prayer_partner_members').insert(members);
    return groupId;
  }

  Future<void> acceptInvite(String partnerGroupId) async {
    await _client
        .from('prayer_partner_members')
        .update({'status': 'accepted'})
        .eq('partner_group_id', partnerGroupId)
        .eq('user_id', _uid);
  }
}
