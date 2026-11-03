import 'dart:math';

class GamePlayer {
  final String uid;
  final String nickname;
  final bool isHost;
  const GamePlayer({required this.uid, required this.nickname, required this.isHost});

  GamePlayer copyWith({String? uid, String? nickname, bool? isHost}) => GamePlayer(
        uid: uid ?? this.uid,
        nickname: nickname ?? this.nickname,
        isHost: isHost ?? this.isHost,
      );
}

enum GameStatus { lobby, playing, finished }

String generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random();
  return String.fromCharCodes(
    List.generate(6, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
  );
}
