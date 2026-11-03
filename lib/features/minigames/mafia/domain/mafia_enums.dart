enum GamePhase {
  lobby,
  roleReveal,
  night,
  day,
  voting,
  roundResult,
  gameOver;

  String get phaseKey {
    switch (this) {
      case GamePhase.lobby: return 'lobby';
      case GamePhase.roleReveal: return 'role_reveal';
      case GamePhase.night: return 'night';
      case GamePhase.day: return 'day';
      case GamePhase.voting: return 'voting';
      case GamePhase.roundResult: return 'round_result';
      case GamePhase.gameOver: return 'game_over';
    }
  }

  static GamePhase fromKey(String key) {
    switch (key) {
      case 'role_reveal': return GamePhase.roleReveal;
      case 'night': return GamePhase.night;
      case 'day': return GamePhase.day;
      case 'voting': return GamePhase.voting;
      case 'round_result': return GamePhase.roundResult;
      case 'game_over': return GamePhase.gameOver;
      default: return GamePhase.lobby;
    }
  }
}

enum MafiaRole {
  citizen,
  mafia,
  police,
  doctor;

  String get key {
    switch (this) {
      case MafiaRole.citizen: return 'citizen';
      case MafiaRole.mafia: return 'mafia';
      case MafiaRole.police: return 'police';
      case MafiaRole.doctor: return 'doctor';
    }
  }

  String get displayName {
    switch (this) {
      case MafiaRole.citizen: return '성도';
      case MafiaRole.mafia: return '이단자';
      case MafiaRole.police: return '목자';
      case MafiaRole.doctor: return '중보기도자';
    }
  }

  String get emoji {
    switch (this) {
      case MafiaRole.citizen: return '✝️';
      case MafiaRole.mafia: return '😈';
      case MafiaRole.police: return '🐑';
      case MafiaRole.doctor: return '🙏';
    }
  }

  String get description {
    switch (this) {
      case MafiaRole.citizen: return '낮에 토론하고 이단자를 찾아내세요';
      case MafiaRole.mafia: return '밤에 성도를 타락시키고 들키지 마세요';
      case MafiaRole.police: return '밤에 1명을 조사해 이단자 여부를 확인하세요';
      case MafiaRole.doctor: return '밤에 1명을 위해 기도해 이단자의 공격을 막으세요';
    }
  }

  static MafiaRole? fromKey(String? key) {
    switch (key) {
      case 'citizen': return MafiaRole.citizen;
      case 'mafia': return MafiaRole.mafia;
      case 'police': return MafiaRole.police;
      case 'doctor': return MafiaRole.doctor;
      default: return null;
    }
  }
}

enum ChatType { public, mafia }

enum ActionType {
  mafiaVote,
  policeInvestigate,
  doctorProtect,
  dayVote;

  String get key {
    switch (this) {
      case ActionType.mafiaVote: return 'mafia_vote';
      case ActionType.policeInvestigate: return 'police_investigate';
      case ActionType.doctorProtect: return 'doctor_protect';
      case ActionType.dayVote: return 'day_vote';
    }
  }
}

enum GameResult { citizenWin, mafiaWin }
