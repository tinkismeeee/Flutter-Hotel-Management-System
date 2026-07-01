import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../promotion/promotion_list_screen.dart';
import '../service/service_list_screen.dart';
import 'daily_revenue_screen.dart';
import 'room_info_list_screen.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'MAISON.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'KHU VỰC STAFF',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tác vụ staff',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.08,
                children: [
                  staffButton(
                    context,
                    title: 'Thông tin phòng',
                    icon: Icons.bed_rounded,
                    screen: const RoomInfoListScreen(),
                  ),
                  staffButton(
                    context,
                    title: 'Dịch vụ',
                    icon: Icons.room_service_rounded,
                    screen: const ServiceListScreen(),
                  ),
                  staffButton(
                    context,
                    title: 'Mã giảm giá',
                    icon: Icons.discount_rounded,
                    screen: const PromotionListScreen(),
                  ),
                  staffButton(
                    context,
                    title: 'Doanh thu ngày',
                    icon: Icons.today_rounded,
                    screen: const DailyRevenueScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget staffButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => openScreen(context, screen),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: AppColors.gold,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
