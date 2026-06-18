import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchContentRepository {
  final _client = Supabase.instance.client;

  Future<String?> _getChurchId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('users')
        .select('church_id')
        .eq('id', uid)
        .maybeSingle();
    return res?['church_id'] as String?;
  }

  Future<List<Map<String, dynamic>>> getScheduleEvents() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];
    return await _client
        .from('schedule_events')
        .select()
        .eq('church_id', churchId)
        .order('date');
  }

  Future<List<Map<String, dynamic>>> getAlbums() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];
    return await _client
        .from('event_albums')
        .select()
        .eq('church_id', churchId)
        .order('event_date', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAlbumPhotos(String albumId) async {
    return await _client
        .from('album_photos')
        .select()
        .eq('album_id', albumId)
        .order('created_at');
  }

  Future<List<Map<String, dynamic>>> getWeeklyWorship() async {
    final churchId = await _getChurchId();
    if (churchId == null) return [];
    return await _client
        .from('weekly_worship')
        .select()
        .eq('church_id', churchId)
        .order('date', ascending: false);
  }
}
