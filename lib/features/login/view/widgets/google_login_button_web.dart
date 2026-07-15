import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleLoginButton extends StatefulWidget {
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
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  static const _webClientId =
      '786154844319-e7a4pucog1mj8mugg2qsh8aeu388i1c1.apps.googleusercontent.com';
  static Future<void>? _initialization;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final signIn = GoogleSignIn.instance;
      await (_initialization ??= signIn.initialize(clientId: _webClientId));
      if (!mounted) return;

      _subscription = signIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: widget.onError,
      );
      setState(() {
        _initialized = true;
      });
    } catch (error) {
      if (mounted) {
        widget.onError(error);
      }
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    final idToken = event.user.authentication.idToken;
    if (idToken == null || idToken.trim().isEmpty) {
      widget.onError(Exception('Google sign-in did not return an ID token.'));
      return;
    }
    widget.onIdToken(idToken);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        key: Key('googleLoginButton'),
        width: 72,
        height: 44,
      );
    }

    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.6,
        child: KeyedSubtree(
          key: const Key('googleLoginButton'),
          child: web.renderButton(),
        ),
      ),
    );
  }
}
