import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/signup_controller.dart';

class SignupPage extends StatefulWidget {
  final ValueChanged<UserModel>? onRegistered;

  const SignupPage({super.key, this.onRegistered});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final formKey = GlobalKey<FormState>();
  final signupController = SignupController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showErrors = false;
  bool isLoading = false;
  bool isPasswordHidden = true;
  String? signupError;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSignup() async {
    setState(() {
      showErrors = true;
      signupError = null;
    });

    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await signupController.signup(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onRegistered?.call(user);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        signupError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? validateFullName(String? value) {
    if (!showErrors) return null;
    if ((value ?? '').trim().isEmpty) return 'Please enter your full name';
    return null;
  }

  String? validateEmail(String? value) {
    if (!showErrors) return null;
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (!showErrors) return null;
    if ((value ?? '').trim().isEmpty) return 'Please enter your password';
    if ((value ?? '').trim().length < 6) {
      return 'Password must be at least 6 characters';
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
      backgroundColor: CustomColors.globalBackground,
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
                const SizedBox(height: 36),
                const Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xFF171725),
                      fontSize: 24,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w700,
                      height: 1.33,
                      letterSpacing: 0.12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Create your account to continue',
                    style: TextStyle(
                      color: Color(0xFF434E58),
                      fontSize: 14,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w400,
                      height: 1.57,
                      letterSpacing: 0.07,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _SignupInputField(
                  label: 'Full Name',
                  hintText: 'Enter your name',
                  controller: fullNameController,
                  validator: validateFullName,
                  onTapOutside: hideErrorsWhenUnfocus,
                ),
                const SizedBox(height: 16),
                _SignupInputField(
                  label: 'E-mail',
                  hintText: 'Enter your email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                  onTapOutside: hideErrorsWhenUnfocus,
                ),
                const SizedBox(height: 16),
                _SignupInputField(
                  label: 'Password',
                  hintText: 'Enter your password',
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
                      color: const Color(0xFF9CA4AB),
                    ),
                  ),
                ),
                if (signupError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    signupError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.buttonBackground,
                      foregroundColor: CustomColors.buttonText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Create An Account',
                            style: TextStyle(
                              color: Color(0xFFFEFEFE),
                              fontSize: 16,
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                              height: 1.50,
                              letterSpacing: 0.08,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: CustomColors.signUpFieldText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Jost',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: CustomColors.buttonBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTapOutside;

  const _SignupInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
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
            color: Color(0xFF171725),
            fontSize: 14,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
            height: 1.57,
            letterSpacing: 0.07,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTapOutside: (event) => onTapOutside?.call(),
          style: const TextStyle(
            color: Color(0xFF171725),
            fontSize: 14,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA4AB),
              fontSize: 14,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w600,
              height: 1.57,
              letterSpacing: 0.07,
            ),
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF171725), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
