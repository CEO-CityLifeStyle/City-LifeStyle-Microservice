class User {
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.favorites,
    required this.createdAt,
    this.avatar,
    this.privacy = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: (json['role'] as String?) ?? 'user',
        favorites: List<String>.from((json['favorites'] as List?) ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        avatar: json['avatar'] as String?,
        privacy: (json['privacy'] as Map<String, dynamic>?) ?? {},
      );

  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatar;
  final List<String> favorites;
  final DateTime createdAt;
  final Map<String, dynamic> privacy;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'name': name,
        'role': role,
        'avatar': avatar,
        'favorites': favorites,
        'createdAt': createdAt.toIso8601String(),
        'privacy': privacy,
      };
}
