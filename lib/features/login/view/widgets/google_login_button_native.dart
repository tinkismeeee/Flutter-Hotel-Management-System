import 'package:flutter/material.dart';

class GoogleLoginButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<String> onIdToken;
  final ValueChanged<Object> onError;

  const GoogleLoginButton({
    super.key,
    required this.enabled,
    required this.onTap,
    required this.onIdToken,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('googleLoginButton'),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Image.asset('assets/imgs/google_img.png'),
      ),
    );
  }
}
