import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/profile_controller.dart';
import 'edit_profile_screen.dart';
import 'id_card_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onLogout;
  final ValueChanged<UserModel> onUserUpdated;
  final Future<void> Function(Locale) onLocaleChanged;
  final ProfileController? controller;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onUserUpdated,
    required this.onLocaleChanged,
    this.controller,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel user;
  late ProfileController controller;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    controller = widget.controller ?? ProfileController();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      user = widget.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : user.username.isNotEmpty
        ? user.username
        : user.email;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 58,
        centerTitle: true,
        title: Text(
          context.tr(AppText.profile),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
            height: 1.44,
            letterSpacing: 0.09,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.10),
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _initials(user),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontFamily: 'Jost',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontFamily: 'Jost',
                                  fontWeight: FontWeight.w600,
                                  height: 1.44,
                                  letterSpacing: 0.09,
                                ),
                              ),
                              if (user.username.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${user.username}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E8E),
                                    fontSize: 14,
                                    fontFamily: 'Jost',
                                    fontWeight: FontWeight.w400,
                                    height: 1.57,
                                    letterSpacing: 0.07,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: const Key('editProfileButton'),
                          onPressed: editProfile,
                          tooltip: context.tr(AppText.editProfile),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: AppColors.field,
                            foregroundColor: AppColors.textPrimary,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      context.tr(AppText.setting),
                      style: const TextStyle(
                        color: AppColors.hint,
                        fontSize: 18,
                        fontFamily: 'Jost',
                        fontWeight: FontWeight.w500,
                        height: 1.44,
                        letterSpacing: 0.09,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingRow(
                      icon: Icons.email_outlined,
                      label: context.tr(AppText.email),
                      value: _profileValue(context, user.email),
                      isMissing: user.email.trim().isEmpty,
                      onTap: editProfile,
                    ),
                    _SettingRow(
                      icon: Icons.phone_outlined,
                      label: context.tr(AppText.phone),
                      value: _profileValue(context, user.phone),
                      isMissing: user.phone.trim().isEmpty,
                      onTap: editProfile,
                    ),
                    _SettingRow(
                      icon: Icons.location_on_outlined,
                      label: context.tr(AppText.address),
                      value: _profileValue(context, user.address),
                      isMissing: user.address.trim().isEmpty,
                      onTap: editProfile,
                    ),
                    _SettingRow(
                      icon: Icons.cake_outlined,
                      label: context.tr(AppText.dateOfBirth),
                      value: _profileValue(
                        context,
                        _dateOnly(user.dateOfBirth),
                      ),
                      isMissing: user.dateOfBirth.trim().isEmpty,
                      onTap: editProfile,
                    ),
                    if (user.userId.isNotEmpty)
                      _SettingRow(
                        icon: Icons.badge_outlined,
                        label: context.tr(AppText.customerId),
                        value: user.userId,
                      ),
                    _SettingRow(
                      icon: Icons.language_rounded,
                      label: context.tr(AppText.language),
                      value:
                          Localizations.localeOf(context).languageCode == 'vi'
                          ? context.tr(AppText.vietnamese)
                          : context.tr(AppText.english),
                      onTap: selectLanguage,
                    ),
                    _SettingRow(
                      icon: Icons.credit_card_outlined,
                      label: context.tr(AppText.identityCard),
                      value: context.tr(
                        user.idCardFont.isNotEmpty && user.idCardBack.isNotEmpty
                            ? AppText.complete
                            : AppText.missing,
                      ),
                      isMissing:
                          user.idCardFont.isEmpty || user.idCardBack.isEmpty,
                      onTap: manageIdCard,
                    ),
                    const Spacer(),
                    _LogoutButton(isLoading: isLoggingOut, onPressed: logout),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> editProfile() async {
    final updatedUser = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(user: user, controller: controller),
      ),
    );
    if (updatedUser == null || !mounted) return;

    await UserModel.updateSavedCurrentUserIfPresent(updatedUser);
    if (!mounted) return;

    setState(() => user = updatedUser);
    widget.onUserUpdated(updatedUser);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(AppText.profileUpdated))));
  }

  Future<void> selectLanguage() async {
    final currentLocale = Localizations.localeOf(context);
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(AppText.selectLanguage),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                title: context.tr(AppText.english),
                locale: const Locale('en'),
                selected: currentLocale.languageCode == 'en',
              ),
              _LanguageOption(
                title: context.tr(AppText.vietnamese),
                locale: const Locale('vi'),
                selected: currentLocale.languageCode == 'vi',
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedLocale == null) return;
    await widget.onLocaleChanged(selectedLocale);
  }

  Future<void> manageIdCard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdCardScreen(
          user: user,
          controller: controller,
          onUserUpdated: widget.onUserUpdated,
        ),
      ),
    );
    try {
      final updated = await controller.fetchProfile(user);
      await UserModel.updateSavedCurrentUserIfPresent(updated);
      if (!mounted) return;
      setState(() => user = updated);
      widget.onUserUpdated(updated);
    } catch (_) {
      // Existing profile remains usable if refresh fails.
    }
  }

  Future<void> logout() async {
    if (isLoggingOut) return;
    setState(() => isLoggingOut = true);

    try {
      await UserModel.clearCurrentUser();
      await widget.onLogout();
    } finally {
      if (mounted) {
        setState(() => isLoggingOut = false);
      }
    }
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMissing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMissing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: AppColors.textPrimary),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontFamily: 'Jost',
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 3,
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isMissing ? AppColors.hint : AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Jost',
                        fontWeight: isMissing
                            ? FontWeight.w500
                            : FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
          indent: 40,
          thickness: 1,
          color: AppColors.border,
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LogoutButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: AppColors.danger.withValues(alpha: 0.055),
          disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.035),
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? Row(
                  key: const ValueKey('logoutLoading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Builder(
                      builder: (context) => Text(
                        context.tr(AppText.signingOut),
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 15,
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('logoutReady'),
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(AppText.logout),
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 16,
                              fontFamily: 'Jost',
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            context.tr(AppText.signOutDescription),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontFamily: 'Jost',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: AppColors.danger,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String _initials(UserModel user) {
  final first = user.firstName.trim();
  final last = user.lastName.trim();
  final value =
      '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}';
  if (value.isNotEmpty) return value.toUpperCase();
  if (user.username.isNotEmpty) return user.username[0].toUpperCase();
  return user.email.isEmpty ? '?' : user.email[0].toUpperCase();
}

String _profileValue(BuildContext context, String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? context.tr(AppText.notProvided) : normalized;
}

String _dateOnly(String value) {
  final normalized = value.trim();
  if (normalized.length < 10) return normalized;
  return normalized.substring(0, 10);
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final Locale locale;
  final bool selected;

  const _LanguageOption({
    required this.title,
    required this.locale,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(locale),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        Icons.translate_rounded,
        color: selected ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
    );
  }
}
