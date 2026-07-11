import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/models/booking_service_model.dart';
import '../../../core/models/payos_payment_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/payment_controller.dart';

class PaymentQrScreen extends StatefulWidget {
  final RoomModel room;
  final String? roomTypeName;
  final List<BookingServiceModel> services;
  final DateTimeRange? stayRange;
  final int nights;
  final int guests;
  final PayOsPaymentModel payment;
  final String? discountCode;
  final double discountAmount;

  const PaymentQrScreen({
    super.key,
    required this.room,
    this.roomTypeName,
    this.services = const [],
    this.stayRange,
    this.nights = 1,
    this.guests = 1,
    required this.payment,
    this.discountCode,
    this.discountAmount = 0,
  });

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  final paymentController = PaymentController();
  late PayOsPaymentModel payment;
  Timer? statusTimer;
  bool isChecking = false;
  String? statusError;

  bool get isPaid => payment.status.toLowerCase() == 'paid';
  bool get isCancelled =>
      ['cancelled', 'expired'].contains(payment.status.toLowerCase());

  @override
  void initState() {
    super.initState();
    payment = widget.payment;
    statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkPaymentStatus(),
    );
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Future<void> checkPaymentStatus() async {
    if (isChecking || isPaid || isCancelled) return;
    isChecking = true;
    try {
      final latest = await paymentController.getPayment(payment.bookingId);
      if (!mounted) return;
      setState(() {
        payment = latest;
        statusError = null;
      });
      if (isPaid || isCancelled) statusTimer?.cancel();
    } catch (error) {
      if (!mounted) return;
      setState(() => statusError = _cleanError(error));
    } finally {
      isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay with PayOS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookingSummary(
              room: widget.room,
              roomTypeName: widget.roomTypeName ?? widget.room.roomTypeName,
              stayRange: widget.stayRange,
              nights: widget.nights,
              guests: widget.guests,
              amount: payment.amount,
            ),
            const SizedBox(height: 20),
            if (isPaid)
              const _PaymentResult(
                icon: Icons.check_circle,
                color: AppColors.success,
                title: 'Payment successful',
                message: 'Your booking has been confirmed.',
              )
            else if (isCancelled)
              const _PaymentResult(
                icon: Icons.cancel,
                color: AppColors.danger,
                title: 'Payment unavailable',
                message: 'This payment link was cancelled or expired.',
              )
            else
              _QrPanel(payment: payment),
            if (widget.services.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ServicesSummary(services: widget.services),
            ],
            if (widget.discountCode != null && widget.discountAmount > 0) ...[
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Discount (${widget.discountCode})',
                value: '-${_formatNumber(widget.discountAmount)} VND',
                valueColor: AppColors.success,
              ),
            ],
            if (statusError != null) ...[
              const SizedBox(height: 12),
              Text(
                statusError!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isPaid
                    ? () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst)
                    : isCancelled
                    ? () => Navigator.of(context).pop()
                    : isChecking
                    ? null
                    : checkPaymentStatus,
                icon: isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isPaid ? Icons.home_outlined : Icons.refresh_outlined,
                      ),
                label: Text(
                  isPaid
                      ? 'Back to home'
                      : isCancelled
                      ? 'Back'
                      : 'Check payment status',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;
  final DateTimeRange? stayRange;
  final int nights;
  final int guests;
  final int amount;

  const _BookingSummary({
    required this.room,
    required this.roomTypeName,
    required this.stayRange,
    required this.nights,
    required this.guests,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room ${room.roomNumber}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roomTypeName,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stayRange != null) ...[
            const SizedBox(height: 12),
            Text(
              '${_formatDate(stayRange!.start)} - ${_formatDate(stayRange!.end)}'
              ' · $nights night${nights > 1 ? 's' : ''}'
              ' · $guests guest${guests > 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '${_formatNumber(amount.toDouble())} VND',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  final PayOsPaymentModel payment;

  const _QrPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (payment.qrCode.isEmpty)
            const SizedBox(
              width: 260,
              height: 260,
              child: Center(child: Icon(Icons.qr_code_2, size: 80)),
            )
          else
            QrImageView(
              data: payment.qrCode,
              version: QrVersions.auto,
              size: 260,
              backgroundColor: Colors.white,
            ),
          const SizedBox(height: 12),
          Text(
            'Order ${payment.orderCode}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _expiryText(payment.expiresAt),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentResult extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _PaymentResult({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 58, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesSummary extends StatelessWidget {
  final List<BookingServiceModel> services;

  const _ServicesSummary({required this.services});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: services
          .map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoRow(
                label: service.name,
                value: '${_formatNumber(_parsePrice(service.price))} VND',
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _expiryText(DateTime? expiresAt) {
  if (expiresAt == null) return 'Complete the transfer in the PayOS session';
  final remaining = expiresAt.difference(DateTime.now());
  if (remaining.isNegative) return 'Payment link expired';
  final minutes = remaining.inMinutes;
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  return 'Expires in $minutes:$seconds';
}

String _formatNumber(double number) {
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

double _parsePrice(String value) => double.tryParse(value) ?? 0;

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
