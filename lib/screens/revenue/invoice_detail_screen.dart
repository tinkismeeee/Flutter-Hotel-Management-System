import 'package:flutter/material.dart';

import '../../models/invoice.dart';
import '../../utils/app_colors.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  String money(double value) {
    final raw = value.round().toString();
    final formatted = raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$formatted VNĐ';
  }

  String shortDate(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value.isEmpty ? 'Chưa có' : value;
  }

  Widget detailRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: emphasized ? AppColors.gold : AppColors.textDark,
                fontSize: emphasized ? 18 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paid = invoice.paymentStatus.toLowerCase() == 'paid';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text('Hóa đơn #${invoice.invoiceId}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, Color(0xFF26375F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    money(invoice.finalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (paid ? Colors.green : AppColors.gold).withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      invoice.paymentStatus.isEmpty
                          ? 'Chưa rõ trạng thái'
                          : invoice.paymentStatus,
                      style: TextStyle(
                        color: paid ? Colors.greenAccent : AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  detailRow('Booking', '#${invoice.bookingId}'),
                  detailRow('Nhân viên', '#${invoice.staffId}'),
                  detailRow('Ngày phát hành', shortDate(invoice.issueDate)),
                  detailRow(
                    'Phương thức thanh toán',
                    invoice.paymentMethod.isEmpty
                        ? 'Chưa có'
                        : invoice.paymentMethod,
                  ),
                  if (invoice.promotionId != null)
                    detailRow('Khuyến mãi', '#${invoice.promotionId}'),
                  const Divider(height: 26),
                  detailRow('Tiền phòng', money(invoice.totalRoomCost)),
                  detailRow('Dịch vụ', money(invoice.totalServiceCost)),
                  detailRow('VAT', money(invoice.vatAmount)),
                  detailRow('Giảm giá', '-${money(invoice.discountAmount)}'),
                  const Divider(height: 26),
                  detailRow(
                    'Tổng thanh toán',
                    money(invoice.finalAmount),
                    emphasized: true,
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
