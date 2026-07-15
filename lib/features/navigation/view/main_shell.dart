import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../../bookings/view/my_bookings_screen.dart';
import '../../home/view/home_screen.dart';
import '../../profile/view/profile_screen.dart';

class MainShell extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onLogout;
  final ValueChanged<UserModel> onUserUpdated;
  final Future<void> Function(Locale) onLocaleChanged;

  const MainShell({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onUserUpdated,
    required this.onLocaleChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;
  int bookingRefreshToken = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(user: widget.user, onProfileTap: () => selectTab(2)),
      MyBookingsScreen(user: widget.user, refreshToken: bookingRefreshToken),
      ProfileScreen(
        user: widget.user,
        onLogout: widget.onLogout,
        onUserUpdated: widget.onUserUpdated,
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ];

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(index: selectedIndex, children: pages),
        bottomNavigationBar: _MainNavigationBar(
          selectedIndex: selectedIndex,
          onSelected: selectTab,
        ),
      ),
    );
  }

  void selectTab(int index) {
    if (index == selectedIndex) return;
    setState(() {
      selectedIndex = index;
      if (index == 1) bookingRefreshToken++;
    });
  }
}

class _MainNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MainNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 60,
            offset: const Offset(0, -20),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 8),
        child: Row(
          children: [
            _NavigationItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: context.tr(AppText.home),
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _NavigationItem(
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month_rounded,
              label: context.tr(AppText.myBooking),
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            _NavigationItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: context.tr(AppText.profile),
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? selectedIcon : icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w600,
                    height: 1.8,
                    letterSpacing: 0.05,
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
