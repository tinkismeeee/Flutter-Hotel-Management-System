import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';

class AccountScreen extends StatelessWidget {
  final UserModel user;
  final Future<void> Function() onLogout;

  const AccountScreen({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final displayName = fullName.isEmpty ? user.username : fullName;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          Text('Account', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 28),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFEEF4FF),
              child: Text(
                _initials(user),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            key: const Key('customerLogoutButton'),
            onPressed: onLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _initials(UserModel user) {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$first$last';
    if (initials.isNotEmpty) return initials.toUpperCase();
    return user.username.isEmpty ? '?' : user.username[0].toUpperCase();
  }
}
