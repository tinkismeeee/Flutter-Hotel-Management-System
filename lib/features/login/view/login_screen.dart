import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/user_model.dart';
import '../../forgot_password/view/forgot_password_screen.dart';
import '../../otp/controller/otp_controller.dart';
import '../../otp/view/otp_screen.dart';
import '../../signup/view/signup_screen.dart';
import '../controller/login_controller.dart';
import 'widgets/google_login_button.dart';

class LoginPage extends StatefulWidget {
  final ValueChanged<UserModel>? onLoggedIn;
  final LoginController? loginController;
  final OtpController? otpController;

  const LoginPage({
    super.key,
    this.onLoggedIn,
    this.loginController,
    this.otpController,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final LoginController loginController;
  late final OtpController otpController;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;
  bool rememberPassword = false;
  String? loginError;

  bool showErrors = false;

  @override
  void initState() {
    super.initState();
    loginController = widget.loginController ?? LoginController();
    otpController = widget.otpController ?? OtpController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() {
      showErrors = true;
      loginError = null;
    });

    final isValid = formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      final user = await loginController.login(
        email: email,
        password: password,
        rememberPassword: rememberPassword,
      );

      if (user.isAdmin || user.isStaff) {
        if (!mounted) return;
        widget.onLoggedIn?.call(user);
        debugPrint('Login successful for user: ${user.username}');
        return;
      }

      await otpController.sendOtp(user.email);

      if (!mounted) return;
      final isVerified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            user: user,
            rememberPassword: rememberPassword,
            controller: otpController,
          ),
        ),
      );

      if (isVerified == true) {
        widget.onLoggedIn?.call(user);
        debugPrint('Login successful for user: ${user.username}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loginError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> handleGoogleLogin() async {
    FocusScope.of(context).unfocus();
    await _handleGoogleLogin(loginController.googleLogin);
  }

  Future<void> handleGoogleLoginWithIdToken(String idToken) async {
    await _handleGoogleLogin(
      () => loginController.googleLoginWithIdToken(idToken),
    );
  }

  Future<void> _handleGoogleLogin(
    Future<UserModel> Function() authenticate,
  ) async {
    setState(() {
      isLoading = true;
      loginError = null;
    });

    try {
      final user = await authenticate();
      if (!mounted) return;
      widget.onLoggedIn?.call(user);
      debugPrint('Google login successful for user: ${user.username}');
    } on GoogleLoginCanceled {
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loginError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void handleGoogleLoginError(Object error) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
      loginError = error.toString().replaceFirst('Exception: ', '');
    });
  }

  void hideErrorsWhenUnfocus() {
    FocusScope.of(context).unfocus();

    setState(() {
      showErrors = false;
    });

    formKey.currentState?.validate();
  }

  String? validateEmail(String? value) {
    if (!showErrors) {
      return null;
    }

    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return context.tr(AppText.enterEmailAddress);
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

    if (!emailRegex.hasMatch(email)) {
      return context.tr(AppText.invalidEmail);
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (!showErrors) {
      return null;
    }

    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return context.tr(AppText.enterPassword);
    }

    return null;
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
                const SizedBox(height: 80),

                Center(
                  child: Text(
                    context.tr(AppText.loginTitle),
                    style: const TextStyle(
                      color: Color(0xFF171725),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cambria',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    context.tr(AppText.loginSubtitle),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CustomColors.loginSmallText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cambria',
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                CustomInputField(
                  label: context.tr(AppText.emailAddress),
                  hintText: context.tr(AppText.enterEmailAddress),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                  onTapOutside: hideErrorsWhenUnfocus,
                ),

                const SizedBox(height: 16),

                CustomInputField(
                  label: context.tr(AppText.password),
                  hintText: context.tr(AppText.enterPassword),
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

                if (loginError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    loginError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: rememberPassword,
                      onChanged: (value) {
                        setState(() {
                          rememberPassword = value ?? false;
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          rememberPassword = !rememberPassword;
                        });
                      },
                      child: Text(
                        context.tr(AppText.rememberMe),
                        style: const TextStyle(
                          color: CustomColors.loginText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      child: Text(
                        context.tr(AppText.forgotPassword),
                        style: const TextStyle(
                          color: CustomColors.forgotPasswordText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
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
                        : Text(
                            context.tr(AppText.login),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Jost',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr(AppText.noAccount),
                      style: const TextStyle(
                        color: CustomColors.signUpFieldText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Jost',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      child: Text(
                        context.tr(AppText.signUp),
                        style: const TextStyle(
                          color: CustomColors.buttonBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Color(0xFFE5E5E5), thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        context.tr(AppText.signInWith),
                        style: const TextStyle(
                          color: CustomColors.loginHintText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Color(0xFFE5E5E5), thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLoginButton(
                      enabled: !isLoading,
                      onTap: handleGoogleLogin,
                      onIdToken: handleGoogleLoginWithIdToken,
                      onError: handleGoogleLoginError,
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

class CustomInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTapOutside;

  const CustomInputField({
    super.key,
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
            color: CustomColors.loginText,
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
          onTapOutside: (event) {
            onTapOutside?.call();
          },
          style: const TextStyle(
            color: CustomColors.loginText,
            fontSize: 14,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: CustomColors.loginHintText,
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
