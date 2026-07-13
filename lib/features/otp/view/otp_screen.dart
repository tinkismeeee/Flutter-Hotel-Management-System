import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/otp_controller.dart';

class OtpScreen extends StatefulWidget {
  final UserModel user;
  final bool rememberPassword;
  final OtpController? controller;

  const OtpScreen({
    super.key,
    required this.user,
    required this.rememberPassword,
    this.controller,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final OtpController otpController;
  final TextEditingController otpTextController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isVerifying = false;
  bool isResending = false;
  String? otpError;

  @override
  void initState() {
    super.initState();
    otpController = widget.controller ?? OtpController();
  }

  @override
  void dispose() {
    otpTextController.dispose();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    FocusScope.of(context).unfocus();
    setState(() => otpError = null);

    if (!formKey.currentState!.validate()) return;

    setState(() => isVerifying = true);

    try {
      await otpController.verifyOtp(
        email: widget.user.email,
        otp: otpTextController.text,
      );

      if (widget.rememberPassword) {
        await UserModel.saveCurrentUser(widget.user);
      } else {
        await UserModel.clearCurrentUser();
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        otpError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  Future<void> resendOtp() async {
    setState(() {
      isResending = true;
      otpError = null;
    });

    try {
      final message = await otpController.sendOtp(widget.user.email);
      otpTextController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        otpError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = isVerifying || isResending;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Xác thực đăng nhập',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nhập mã OTP 4 số đã gửi đến\n${widget.user.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                TextFormField(
                  controller: otpTextController,
                  autofocus: true,
                  enabled: !isBusy,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 16,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '0000',
                    errorText: null,
                  ),
                  validator: (value) {
                    if ((value ?? '').length != 4) {
                      return 'Vui lòng nhập đủ 4 số OTP.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!isBusy) verifyOtp();
                  },
                ),
                if (otpError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    otpError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isBusy ? null : verifyOtp,
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác nhận'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isBusy ? null : resendOtp,
                  child: isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi lại mã OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
