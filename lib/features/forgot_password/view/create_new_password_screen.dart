import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/forgot_password_controller.dart';

class CreateNewPasswordPage extends StatefulWidget {
  final UserModel user;

  const CreateNewPasswordPage({super.key, required this.user});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final formKey = GlobalKey<FormState>();
  final forgotPasswordController = ForgotPasswordController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showErrors = false;
  bool isLoading = false;
  bool isPasswordHidden = true;
  String? passwordError;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleUpdatePassword() async {
    setState(() {
      showErrors = true;
      passwordError = null;
    });

    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await forgotPasswordController.updatePassword(
        user: widget.user,
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        passwordError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? validatePassword(String? value) {
    if (!showErrors) return null;
    final password = (value ?? '').trim();
    if (password.isEmpty) return 'Please enter your new password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (!showErrors) return null;
    final confirmPassword = (value ?? '').trim();
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (confirmPassword != passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  void hideErrorsWhenUnfocus() {
    FocusScope.of(context).unfocus();
    setState(() {
      showErrors = false;
    });
    formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 56),
                const Center(
                  child: Text(
                    'Create New Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    widget.user.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 46),
                _PasswordField(
                  label: 'New Password',
                  hintText: 'Enter your new password',
                  controller: passwordController,
                  obscureText: isPasswordHidden,
                  validator: validatePassword,
                  onTapOutside: hideErrorsWhenUnfocus,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.hint,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  label: 'Confirm Password',
                  hintText: 'Enter your password again',
                  controller: confirmPasswordController,
                  obscureText: isPasswordHidden,
                  validator: validateConfirmPassword,
                  onTapOutside: hideErrorsWhenUnfocus,
                ),
                if (passwordError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    passwordError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleUpdatePassword,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final VoidCallback? onTapOutside;

  const _PasswordField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    this.suffixIcon,
    this.validator,
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          onTapOutside: (event) => onTapOutside?.call(),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
