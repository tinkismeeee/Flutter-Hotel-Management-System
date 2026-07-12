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
            // Header: Giới hạn chiều cao tối đa để tránh bị kéo quá dài trên màn hình lớn
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

            // Dùng LayoutBuilder để tính toán số lượng cột dựa trên chiều rộng màn hình
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;

                  // Mặc định cho điện thoại
                  int crossAxisCount = 2;
                  double aspectRatio = 1.1;

                  if (width > 1200) {
                    // Màn hình Máy tính lớn (PC / Web)
                    crossAxisCount = 6;
                    aspectRatio = 1.2;
                  } else if (width > 800) {
                    // Màn hình Máy tính nhỏ hoặc Tablet ngang
                    crossAxisCount = 4;
                    aspectRatio = 1.15;
                  } else if (width > 600) {
                    // Màn hình Máy tính bảng (Tablet dọc)
                    crossAxisCount = 3;
                    aspectRatio = 1.1;
                  }

                  // Bọc GridView trong một Center + ConstrainedBox để nội dung không bị bè quá rộng trên PC
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: GridView.count(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: aspectRatio,
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
                            icon: Icons.logout_rounded, // Đổi icon sang logout cho đúng nghĩa
                            screen: const EmptyScreen(title: 'Logout'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
      borderRadius: BorderRadius.circular(20),
      onTap: () => openScreen(context, screen),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppColors.gold,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center, // Căn giữa chữ đề phòng tên danh mục dài
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Nếu chữ quá dài tự động thêm dấu "..." thay vì vỡ dòng
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
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