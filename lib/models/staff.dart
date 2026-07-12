class Staff {
  final int userId;
  final String username;
  final String email;
  final String passwordHash;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final bool isActive;

  Staff({
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.isActive,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['password_hash'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}