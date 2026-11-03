import 'mafia_enums.dart';

class MafiaRoom {
  final String id;
  final String code;
  final String hostId;
  final String status;
  final GamePhase phase;
  final DateTime? phaseEndAt;
  final int round;

  const MafiaRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.phase,
    this.phaseEndAt,
    required this.round,
  });

  factory MafiaRoom.fromJson(Map<String, dynamic> json) => MafiaRoom(
        id: json['id'] as String,
        code: json['code'] as String,
        hostId: json['host_id'] as String,
        status: json['status'] as String? ?? 'waiting',
        phase: GamePhase.fromKey(json['phase'] as String? ?? 'lobby'),
        phaseEndAt: json['phase_end_at'] != null
            ? DateTime.parse(json['phase_end_at'] as String).toLocal()
            : null,
        round: json['round'] as int? ?? 0,
      );
}

class MafiaPlayer {
  final String id;
  final String roomId;
  final String userId;
  final String nickname;
  final MafiaRole? role;
  final bool isAlive;
  final List<String> mafiaUids;

  const MafiaPlayer({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.nickname,
    this.role,
    required this.isAlive,
    this.mafiaUids = const [],
  });

  factory MafiaPlayer.fromJson(Map<String, dynamic> json) {
    List<String> mafiaUids = [];
    if (json['mafia_uids'] != null) {
      mafiaUids = List<String>.from(json['mafia_uids'] as List);
    }
    return MafiaPlayer(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      role: MafiaRole.fromKey(json['role'] as String?),
      isAlive: json['is_alive'] as bool? ?? true,
      mafiaUids: mafiaUids,
    );
  }

  MafiaPlayer copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? nickname,
    MafiaRole? role,
    bool? isAlive,
    List<String>? mafiaUids,
  }) =>
      MafiaPlayer(
        id: id ?? this.id,
        roomId: roomId ?? this.roomId,
        userId: userId ?? this.userId,
        nickname: nickname ?? this.nickname,
        role: role ?? this.role,
        isAlive: isAlive ?? this.isAlive,
        mafiaUids: mafiaUids ?? this.mafiaUids,
      );
}

class MafiaChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String nickname;
  final String content;
  final ChatType chatType;
  final int round;
  final DateTime createdAt;

  const MafiaChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.nickname,
    required this.content,
    required this.chatType,
    required this.round,
    required this.createdAt,
  });

  factory MafiaChatMessage.fromJson(Map<String, dynamic> json) =>
      MafiaChatMessage(
        id: json['id'] as String,
        roomId: json['room_id'] as String,
        senderId: json['sender_id'] as String,
        nickname: json['nickname'] as String,
        content: json['content'] as String,
        chatType: json['chat_type'] == 'mafia' ? ChatType.mafia : ChatType.public,
        round: json['round'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class MafiaGameLog {
  final String id;
  final String roomId;
  final int round;
  final String event; // killed, executed, saved
  final String? targetId;
  final String? targetNickname;
  final String? targetRole;

  const MafiaGameLog({
    required this.id,
    required this.roomId,
    required this.round,
    required this.event,
    this.targetId,
    this.targetNickname,
    this.targetRole,
  });

  factory MafiaGameLog.fromJson(Map<String, dynamic> json) => MafiaGameLog(
        id: json['id'] as String,
        roomId: json['room_id'] as String,
        round: json['round'] as int,
        event: json['event'] as String,
        targetId: json['target_id'] as String?,
        targetNickname: json['target_nickname'] as String?,
        targetRole: json['target_role'] as String?,
      );
}
