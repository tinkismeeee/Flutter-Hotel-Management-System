import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../utils/app_colors.dart';

class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final userIdController = TextEditingController();
  final checkInController = TextEditingController();
  final checkOutController = TextEditingController();
  final totalGuestsController = TextEditingController();
  final roomIdsController = TextEditingController();
  final promotionCodeController = TextEditingController();

  // Lưu trữ biến DateTime thực tế để tính toán logic ràng buộc giữa 2 ngày
  DateTime? selectedCheckInDate;

  bool isLoading = false;

  @override
  void dispose() {
    userIdController.dispose();
    checkInController.dispose();
    checkOutController.dispose();
    totalGuestsController.dispose();
    roomIdsController.dispose();
    promotionCodeController.dispose();
    super.dispose();
  }

  // Sửa lại hàm pickDateTime để xử lý logic khóa ngày
  Future<void> pickDateTime(
    TextEditingController controller,
    bool isCheckIn,
  ) async {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Đưa về 00:00 hôm nay

    // Xác định mốc ngày đầu tiên được phép chọn (firstDate) và ngày mặc định (initialDate)
    DateTime firstDate;
    DateTime initialDate;

    if (isCheckIn) {
      // Nếu là Check-in: Chỉ cho chọn từ hôm nay trở đi
      firstDate = today;
      initialDate = today;
    } else {
      // Nếu là Check-out: Bắt buộc từ ngày Check-in đã chọn trở đi (nếu chưa chọn Check-in thì lấy hôm nay)
      firstDate = selectedCheckInDate ?? today;
      initialDate = selectedCheckInDate ?? today;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate, // Áp dụng ràng buộc ngày ở đây
      lastDate: DateTime(
        now.year + 5,
      ), // Cho phép đặt trước tối đa 5 năm tính từ thời điểm hiện tại
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );

    if (time == null) return;
    if (!mounted) return;

    // Lưu lại ngày Check-in để làm mốc chặn cho ngày Check-out
    if (isCheckIn) {
      setState(() {
        selectedCheckInDate = date;
        // Nếu ngày Check-out hiện tại nhỏ hơn ngày Check-in mới chọn -> Xóa ngày Check-out cũ
        checkOutController.clear();
      });
    }

    controller.text =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  List<int> parseRoomIds(String text) {
    return text
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
  }

  Future<void> addBooking() async {
    if (userIdController.text.trim().isEmpty ||
        checkInController.text.trim().isEmpty ||
        checkOutController.text.trim().isEmpty ||
        totalGuestsController.text.trim().isEmpty ||
        roomIdsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final roomIds = parseRoomIds(roomIdsController.text.trim());

    if (roomIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room IDs không hợp lệ. Ví dụ: 1,2')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await BookingService.addBooking(
      userId: int.parse(userIdController.text.trim()),
      checkIn: checkInController.text.trim(),
      checkOut: checkOutController.text.trim(),
      totalGuests: int.parse(totalGuestsController.text.trim()),
      roomIds: roomIds,
      promotionCode: promotionCodeController.text.trim().isEmpty
          ? null
          : promotionCodeController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Thêm booking thành công' : 'Thêm booking thất bại',
        ),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType type = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: type,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: AppColors.textGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.gold, width: 2),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          ),
          const Expanded(
            child: Text(
              'Thêm booking',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            header(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  inputField(
                    'User ID',
                    userIdController,
                    type: TextInputType.number,
                  ),
                  inputField(
                    'Check-in',
                    checkInController,
                    readOnly: true,
                    // Truyền flag true báo hiệu đây là Check-in
                    onTap: () => pickDateTime(checkInController, true),
                  ),
                  inputField(
                    'Check-out',
                    checkOutController,
                    readOnly: true,
                    // Truyền flag false báo hiệu đây là Check-out
                    onTap: () => pickDateTime(checkOutController, false),
                  ),
                  inputField(
                    'Số khách',
                    totalGuestsController,
                    type: TextInputType.number,
                  ),
                  inputField('Room IDs, ví dụ: 1,2', roomIdsController),
                  inputField('Mã khuyến mãi nếu có', promotionCodeController),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : addBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Đang thêm...' : 'Thêm booking',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
