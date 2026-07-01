import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../controller/forgot_password_controller.dart';
import 'create_new_password_screen.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final formKey = GlobalKey<FormState>();
  final forgotPasswordController = ForgotPasswordController();
  final emailController = TextEditingController();
  bool showErrors = false;
  bool isLoading = false;
  String? emailError;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> handleNext() async {
    setState(() {
      showErrors = true;
      emailError = null;
    });

    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await forgotPasswordController.findUserByEmail(
        emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateNewPasswordPage(user: user),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        emailError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? validateEmail(String? value) {
    if (!showErrors) return null;

    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email must be filled';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      return 'Please enter a valid email';
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
                    'Forgot Password',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Enter your email address to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 46),
                const Text(
                  'E-mail',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                    letterSpacing: 0.07,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                  onTapOutside: (event) => hideErrorsWhenUnfocus(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                  ),
                ),
                if (emailError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    emailError!,
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
                    onPressed: isLoading ? null : handleNext,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Next'),
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
