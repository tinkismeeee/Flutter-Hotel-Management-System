import '../../../core/models/user_model.dart';

class LoginController {
  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    final customers = await UserModel.fetchAllUsers();
    final user = customers.firstWhere(
      (customer) => customer.email == email && customer.password == password,
      orElse: () => throw Exception('Invalid email or password'),
    );

    if (rememberPassword) {
      await UserModel.saveCurrentUser(user);
    } else {
      await UserModel.clearCurrentUser();
    }

    return user;
  }
}
