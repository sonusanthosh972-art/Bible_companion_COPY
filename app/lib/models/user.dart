/// Authenticated (or guest) user as returned by the backend.
class AppUser {
  final String id;
  final String? email;
  final bool isGuest;
  final String? nickname;
  final String? avatar;
  final String language;

  const AppUser({
    required this.id,
    required this.email,
    required this.isGuest,
    required this.nickname,
    required this.avatar,
    required this.language,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        isGuest: json['isGuest'] as bool? ?? false,
        nickname: json['nickname'] as String?,
        avatar: json['avatar'] as String?,
        language: json['language'] as String? ?? 'en',
      );

  AppUser copyWith({String? nickname, String? avatar, String? language}) =>
      AppUser(
        id: id,
        email: email,
        isGuest: isGuest,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        language: language ?? this.language,
      );

  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : (email ?? 'Guest');
}
