import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/app_colors.dart';

class EditBookingScreen extends StatefulWidget {
  final Booking booking;

  const EditBookingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late TextEditingController checkInController;
  late TextEditingController checkOutController;

  late String status;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    checkInController = TextEditingController(
      text: formatDateTime(widget.booking.checkIn),
    );
    checkOutController = TextEditingController(
      text: formatDateTime(widget.booking.checkOut),
    );

    status = widget.booking.status.isEmpty ? 'confirmed' : widget.booking.status;
  }

  String formatDateTime(String value) {
    if (value.isEmpty) return '';
    if (value.contains('T') && value.length >= 16) {
      return '${value.substring(0, 16).replaceAll('T', ' ')}:00';
    }
    return value;
  }

  String shortDateTime(String value) {
    if (value.isEmpty) return 'Không có';
    if (value.contains('T') && value.length >= 16) {
      return value.substring(0, 16).replaceAll('T', ' ');
    }
    return value;
  }

  String showNull(dynamic value) {
    if (value == null) return 'Không có';
    if (value.toString().isEmpty) return 'Không có';
    return value.toString();
  }

  @override
  void dispose() {
    checkInController.dispose();
    checkOutController.dispose();
    super.dispose();
  }

  Future<void> pickDateTime(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2025, 11, 20),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );

    if (time == null) return;

    controller.text =
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> updateBooking() async {
    setState(() {
      isLoading = true;
    });

    final success = await BookingService.updateBooking(
      id: widget.booking.bookingId,
      status: status,
      checkIn: checkInController.text.trim(),
      checkOut: checkOutController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Cập nhật booking thành công' : 'Cập nhật booking thất bại',
        ),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gold.withOpacity(0.18),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Booking #${widget.booking.bookingId}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          infoRow('Booking ID', widget.booking.bookingId.toString()),
          infoRow('User ID', widget.booking.userId.toString()),
          infoRow('Username', widget.booking.username),
          infoRow('Ngày đặt', shortDateTime(widget.booking.bookingDate)),
          infoRow('Số khách', widget.booking.totalGuests.toString()),

        ],
      ),
    );
  }

  Widget inputField(
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: AppColors.textGray,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.gold,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget statusDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'confirmed', child: Text('confirmed')),
            DropdownMenuItem(value: 'completed', child: Text('completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
            DropdownMenuItem(value: 'pending', child: Text('pending')),
          ],
          onChanged: (value) {
            setState(() {
              status = value ?? 'confirmed';
            });
          },
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
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.gold,
            ),
          ),
          const Expanded(
            child: Text(
              'Sửa booking',
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
                  infoCard(),

                  const Text(
                    'Thông tin có thể chỉnh sửa',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  statusDropdown(),

                  inputField(
                    'Check-in',
                    checkInController,
                    readOnly: true,
                    onTap: () => pickDateTime(checkInController),
                  ),

                  inputField(
                    'Check-out',
                    checkOutController,
                    readOnly: true,
                    onTap: () => pickDateTime(checkOutController),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : updateBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Đang cập nhật...' : 'Cập nhật booking',
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