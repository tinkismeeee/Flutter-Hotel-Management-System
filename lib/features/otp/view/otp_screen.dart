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
  final FocusNode otpFocusNode = FocusNode();

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
    otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    FocusScope.of(context).unfocus();
    setState(() => otpError = null);

    if (otpTextController.text.length != 4) {
      setState(() => otpError = 'Please enter the complete 4-digit OTP code.');
      otpFocusNode.requestFocus();
      return;
    }

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
    final otp = otpTextController.text;
    final activeIndex = otp.length.clamp(0, 3);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        toolbarHeight: 64,
        leadingWidth: 88,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
          child: IconButton(
            onPressed: isBusy ? null : () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFEFEFE),
              foregroundColor: const Color(0xFF171725),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back, size: 24),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF171725),
                  fontSize: 24,
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                  letterSpacing: 0.12,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'We have just sent you 4 digit code via your email ',
                      style: TextStyle(
                        color: Color(0xFF434E58),
                        fontSize: 14,
                        fontFamily: 'Jost',
                        fontWeight: FontWeight.w400,
                        height: 1.57,
                        letterSpacing: 0.07,
                      ),
                    ),
                    TextSpan(
                      text: widget.user.email,
                      style: const TextStyle(
                        color: Color(0xFF171725),
                        fontSize: 14,
                        fontFamily: 'Jost',
                        fontWeight: FontWeight.w400,
                        height: 1.57,
                        letterSpacing: 0.07,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 272,
                  height: 56,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          final isActive = index == activeIndex;
                          final isFilled = index < otp.length;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFEFEFE)
                                  : const Color(0xFFF6F6F6),
                              border: isActive
                                  ? Border.all(color: const Color(0xFF2852AF))
                                  : null,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              isFilled ? otp[index] : '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF171725)
                                    : const Color(0xFF9CA4AB),
                                fontSize: 24,
                                fontFamily: 'Jost',
                                fontWeight: FontWeight.w700,
                                height: 1.33,
                                letterSpacing: 0.12,
                              ),
                            ),
                          );
                        }),
                      ),
                      Positioned.fill(
                        child: TextField(
                          controller: otpTextController,
                          focusNode: otpFocusNode,
                          autofocus: true,
                          enabled: !isBusy,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 4,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: const TextStyle(color: Colors.transparent),
                          cursorColor: Colors.transparent,
                          decoration: const InputDecoration(
                            filled: false,
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) {
                            setState(() => otpError = null);
                          },
                          onSubmitted: (_) {
                            if (!isBusy) verifyOtp();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (otpError != null) ...[
                const SizedBox(height: 12),
                Text(
                  otpError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isBusy ? null : verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2852AF),
                    foregroundColor: const Color(0xFFFEFEFE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFEFEFE),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
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
              TextButton(
                onPressed: isBusy ? null : resendOtp,
                child: isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Didn't receive code? ",
                              style: TextStyle(color: Color(0xFF66707A)),
                            ),
                            TextSpan(
                              text: 'Resend Code',
                              style: TextStyle(color: Color(0xFF2852AF)),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                          letterSpacing: 0.08,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
