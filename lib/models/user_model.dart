class User {
  final int id;
  final String username;
  final String role;
  final bool approved;
  final String? totpSecret;
  
  const User({
    required this.id,
    required this.username,
    required this.role,
    required this.approved,
    this.totpSecret,
  });
  
  bool get isAdmin => role == 'admin';
  
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      role: map['role'],
      approved: map['approved'] == 1,
      totpSecret: map['totp_secret'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'approved': approved ? 1 : 0,
      'totp_secret': totpSecret,
    };
  }
  
  User copyWith({
    int? id,
    String? username,
    String? role,
    bool? approved,
    String? totpSecret,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      totpSecret: totpSecret ?? this.totpSecret,
    );
  }
}