import 'mafia_entities.dart';
import 'mafia_enums.dart';

class CheckVictoryUseCase {
  GameResult? call(List<MafiaPlayer> players) {
    final alive = players.where((p) => p.isAlive).toList();
    final aliveMafia = alive.where((p) => p.role == MafiaRole.mafia).length;
    final aliveCitizens = alive.where((p) => p.role != MafiaRole.mafia).length;

    if (aliveMafia == 0) return GameResult.citizenWin;
    if (aliveMafia >= aliveCitizens) return GameResult.mafiaWin;
    return null;
  }

  /// 인원수별 역할 배정표
  static List<MafiaRole> buildRoleList(int count) {
    assert(count >= 1 && count <= 10);
    final Map<MafiaRole, int> config = switch (count) {
      4 => {MafiaRole.mafia: 1, MafiaRole.citizen: 3},
      5 => {MafiaRole.mafia: 1, MafiaRole.police: 1, MafiaRole.citizen: 3},
      6 => {MafiaRole.mafia: 2, MafiaRole.police: 1, MafiaRole.citizen: 3},
      7 => {MafiaRole.mafia: 2, MafiaRole.police: 1, MafiaRole.doctor: 1, MafiaRole.citizen: 3},
      8 => {MafiaRole.mafia: 2, MafiaRole.police: 1, MafiaRole.doctor: 1, MafiaRole.citizen: 4},
      9 => {MafiaRole.mafia: 3, MafiaRole.police: 1, MafiaRole.doctor: 1, MafiaRole.citizen: 4},
      _ => {MafiaRole.mafia: 3, MafiaRole.police: 1, MafiaRole.doctor: 1, MafiaRole.citizen: 5},
    };
    final roles = <MafiaRole>[];
    config.forEach((role, n) {
      for (var i = 0; i < n; i++) roles.add(role);
    });
    return roles;
  }
}
