class LeaderboardEntry {
  final String? nickname;
  final String? avatar;
  final int xp;
  final int level;

  const LeaderboardEntry({
    required this.nickname,
    required this.avatar,
    required this.xp,
    required this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        nickname: json['nickname'] as String?,
        avatar: json['avatar'] as String?,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
      );
}
