class AuthResult {
  final String token;
  final String userId;
  final DateTime expiryDate;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String userRole;

  AuthResult({
    required this.token,
    required this.userId,
    required this.expiryDate,
    this.name,
    this.email,
    this.photoUrl,
    required this.userRole,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      userId: json['userId'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      userRole: json['userRole'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'expiryDate': expiryDate.toIso8601String(),
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'userRole': userRole,
    };
  }

  // Calculate time until token expires
  Duration get timeUntilExpiry => expiryDate.difference(DateTime.now());

  // Calculate expiry duration in seconds
  int get expiresIn => timeUntilExpiry.inSeconds;
}
