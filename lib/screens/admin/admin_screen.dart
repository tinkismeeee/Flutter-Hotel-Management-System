import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../employee/employee_list_screen.dart';
import '../room/room_list_screen.dart';
import '../room_type/room_type_list_screen.dart';
import '../booking/booking_list_screen.dart';
import '../service/service_list_screen.dart';
import '../promotion/promotion_list_screen.dart';
import '../revenue/revenue_dashboard_screen.dart';
import '../customer/customer_list_screen.dart';
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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
              child: Column(
                children: const [
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
                    'QUẢN TRỊ KHÁCH SẠN',
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Danh mục quản lý',
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
                  adminButton(
                    context,
                    title: 'Nhân viên',
                    icon: Icons.people_alt_rounded,
                    screen: const EmployeeListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Khách hàng',
                    icon: Icons.person_rounded,
                    screen: const CustomerListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Phòng',
                    icon: Icons.bed_rounded,
                    screen: const RoomListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Loại phòng',
                    icon: Icons.meeting_room_rounded,
                    screen: const RoomTypeListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Booking',
                    icon: Icons.calendar_month_rounded,
                    screen: const BookingListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Dịch vụ',
                    icon: Icons.room_service_rounded,
                    screen: const ServiceListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Mã giảm giá',
                    icon: Icons.discount_rounded,
                    screen: const PromotionListScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Doanh thu',
                    icon: Icons.bar_chart_rounded,
                    screen: const RevenueDashboardScreen(),
                  ),
                  adminButton(
                    context,
                    title: 'Logout',
                    icon: Icons.bar_chart_rounded,
                    screen: const EmptyScreen(title: 'Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminButton(
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
              color: Colors.black.withOpacity(0.08),
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
                color: AppColors.gold.withOpacity(0.16),
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

class EmptyScreen extends StatelessWidget {
  final String title;

  const EmptyScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}