import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
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

  Future<List<Map<String, dynamic>>> getNotifications() async {
    return await _client
        .from('notifications')
        .select()
        .eq('receiver_id', _uid)
        .order('created_at', ascending: false)
        .limit(50);
  }

  Future<int> getUnreadCount() async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('receiver_id', _uid)
        .eq('is_read', false);
    return (res as List).length;
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', _uid)
        .eq('is_read', false);
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> sendPrayNotification({
    required String recipientId,
    required String prayerRequestId,
    required String fromNickname,
  }) async {
    if (recipientId == _uid) return;
    final churchId = await _getChurchId();
    await _client.from('notifications').insert({
      'receiver_id': recipientId,
      'church_id': churchId,
      'type': 'prayed_for_you',
      'sender_name': fromNickname,
      'message': '$fromNickname님이 당신을 위해 기도하였습니다.',
    });
  }

  Future<void> sendPartnerInviteNotification({
    required String recipientId,
    required String partnerGroupId,
    required String partnerGroupName,
    required String fromNickname,
  }) async {
    final churchId = await _getChurchId();
    await _client.from('notifications').insert({
      'receiver_id': recipientId,
      'church_id': churchId,
      'type': 'partner_invite',
      'sender_name': fromNickname,
      'message': '$fromNickname님이 파트너 그룹 "$partnerGroupName"에 초대하였습니다.',
      'url': partnerGroupId,
    });
  }
}
