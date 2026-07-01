class UserModel {
  final String userId;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String dateOfBirth;
  final String idCardFont;
  final String idCardBack;
  final bool isActive;

  // Constructor
  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    this.idCardFont = "",
    this.idCardBack = "",
    this.isActive = true,
  });

  // factory UserModel.fromJson(Map<String, dynamic> json) {
  //   return UserModel(
  //     userId: json['user_id'] ?? '',
  //     username: json['username'] ?? '',
  //     email: json['email'] ?? '',
  //     password: json['password_hash'] ?? '',
  //     firstName: json['first_name'] ?? '',
  //     lastName: json['last_name'] ?? '',
  //     phone: json['phone_number'] ?? '',
  //     address: json['address'] ?? '',
  //     dateOfBirth: json['date_of_birth'] ?? '',
  //     idCardFont: json['id_card_front_image_url'] ?? '',
  //     idCardBack: json['id_card_back_image_url'] ?? '',
  //     isActive: json['is_active'] ?? true,
  //   );
  // }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'user_id': String userId,
        'username': String username,
        'email': String email,
        'password_hash': String password,
        'first_name': String firstName,
        'last_name': String lastName,
        'phone_number': String phone,
        'address': String address,
        'date_of_birth': String dateOfBirth,
        'id_card_front_image_url': String idCardFont,
        'id_card_back_image_url': String idCardBack,
        'is_active': bool isActive
      } => UserModel(
          userId: userId,
          username: username,
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          address: address,
          dateOfBirth: dateOfBirth,
          idCardFont: idCardFont,
          idCardBack: idCardBack,
          isActive: isActive),
      _ => throw Exception('Fail to load user data from API'),
    };
  }
}