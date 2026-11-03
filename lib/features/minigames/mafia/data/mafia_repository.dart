import '../domain/mafia_entities.dart';
import '../domain/mafia_enums.dart';

abstract class MafiaRepository {
  Future<MafiaRoom> createRoom(String nickname);
  Future<MafiaRoom> joinRoom(String code, String nickname);
  Future<void> startGame(String roomId);
  Future<MafiaPlayer> getMyPlayer(String roomId);
  Future<List<MafiaPlayer>> getPlayers(String roomId);
  Future<List<MafiaChatMessage>> getMessages(String roomId, ChatType type, int round);
  Future<List<MafiaGameLog>> getLogs(String roomId, int round);
  Future<void> submitNightAction({
    required String roomId,
    required int round,
    required String targetId,
    required ActionType actionType,
  });
  Future<void> sendChatMessage({
    required String roomId,
    required String content,
    required ChatType chatType,
    required int round,
    required String nickname,
  });
  Future<void> submitVote({
    required String roomId,
    required int round,
    required String targetId,
  });
  Future<String?> getPoliceResult(String roomId, int round);
  Future<void> resolveNight(String roomId, int round);
  Future<void> resolveVote(String roomId, int round);
  Future<void> transitionPhase({
    required String roomId,
    required String phase,
    required DateTime phaseEndAt,
    int? round,
  });
  Future<void> leaveRoom(String roomId);
}
