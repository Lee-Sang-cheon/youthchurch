import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';

class GroupPhotoFeed extends StatefulWidget {
  final String cellGroupId;
  const GroupPhotoFeed({super.key, required this.cellGroupId});

  @override
  State<GroupPhotoFeed> createState() => _GroupPhotoFeedState();
}

class _GroupPhotoFeedState extends State<GroupPhotoFeed> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _uploading = false;

  String get _myUid => _client.auth.currentUser?.id ?? '';
  String get _myNickname =>
      _client.auth.currentUser?.userMetadata?['nickname'] as String? ?? '나';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _cleanup() async {
    try {
      await _client.rpc('cleanup_old_group_posts');
    } catch (_) {}
  }

  Future<void> _load() async {
    await _cleanup();
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('group_posts')
          .select()
          .eq('cell_group_id', widget.cellGroupId)
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) setState(() => _posts = List<Map<String, dynamic>>.from(data));
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (picked == null) return;

    final captionCtrl = TextEditingController();
    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CaptionSheet(
        imageFile: File(picked.path),
        captionCtrl: captionCtrl,
      ),
    );
    if (confirmed != true) return;

    setState(() => _uploading = true);
    try {
      final ext = picked.path.split('.').last;
      final path = 'groups/${widget.cellGroupId}/$_myUid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await File(picked.path).readAsBytes();

      await _client.storage.from('group-photos').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
      );

      final url = _client.storage.from('group-photos').getPublicUrl(path);

      await _client.from('group_posts').insert({
        'cell_group_id': widget.cellGroupId,
        'user_id': _myUid,
        'nickname': _myNickname,
        'photo_url': url,
        'caption': captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
      });

      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
        child: Glass(
          radius: 20,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: const Text('카메라로 촬영', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('앨범에서 선택', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1030),
        title: const Text('삭제할까요?', style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _client.from('group_posts').delete().eq('id', postId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.photo_camera_outlined, size: 48, color: AC.muted),
                              SizedBox(height: 12),
                              Text('아직 사진이 없어요', style: TextStyle(color: AC.muted, fontSize: 14)),
                              SizedBox(height: 4),
                              Text('+ 버튼으로 지금 이 순간을 공유해보세요', style: TextStyle(color: AC.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _posts.length,
                      itemBuilder: (_, i) => _PostCard(
                        post: _posts[i],
                        isMe: _posts[i]['user_id'] == _myUid,
                        onDelete: () => _deletePost(_posts[i]['id'] as String),
                      ),
                    ),
        ),

        // 업로드 중 오버레이
        if (_uploading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('업로드 중...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),

        // 업로드 버튼
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            onPressed: _uploading ? null : _pickAndUpload,
            backgroundColor: AC.light,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_a_photo_rounded),
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isMe;
  final VoidCallback onDelete;

  const _PostCard({required this.post, required this.isMe, required this.onDelete});

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final caption = post['caption'] as String?;
    final nickname = post['nickname'] as String? ?? '?';
    final photoUrl = post['photo_url'] as String? ?? '';
    final createdAt = post['created_at'] as String?;

    return GestureDetector(
      onLongPress: isMe ? onDelete : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AC.light.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        nickname.isNotEmpty ? nickname[0] : '?',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AC.light),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(_timeAgo(createdAt),
                            style: const TextStyle(fontSize: 11, color: AC.muted)),
                      ],
                    ),
                  ),
                  if (isMe)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.more_horiz_rounded, color: AC.muted, size: 20),
                    ),
                ],
              ),
            ),

            // 사진
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image_rounded, color: AC.muted),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // 캡션
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Text(caption,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _CaptionSheet extends StatelessWidget {
  final File imageFile;
  final TextEditingController captionCtrl;

  const _CaptionSheet({required this.imageFile, required this.captionCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(imageFile, height: 240, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '한 마디 남기기 (선택)',
                hintStyle: const TextStyle(color: AC.muted),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AC.muted,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AC.light,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('공유하기', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
