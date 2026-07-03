import 'package:flutter/material.dart';

import '../../../core/models/booking_service_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import 'payment_qr_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final RoomModel room;
  final String roomTypeName;
  final UserModel user;
  final List<BookingServiceModel> services;
  final DateTimeRange? stayRange;
  final int nights;
  final int guests;
  final double totalPrice;

  const PaymentConfirmationScreen({
    super.key,
    required this.room,
    required this.roomTypeName,
    required this.user,
    required this.services,
    required this.stayRange,
    required this.nights,
    required this.guests,
    required this.totalPrice,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final promoController = TextEditingController();
  String? promoError;
  String? appliedCode;
  double discountRate = 0;

  double get discountAmount => widget.totalPrice * discountRate;
  double get finalTotal => widget.totalPrice - discountAmount;

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(
              room: widget.room,
              roomTypeName: widget.roomTypeName,
              stayRange: widget.stayRange,
              nights: widget.nights,
              guests: widget.guests,
            ),
            const SizedBox(height: 18),
            _ServicesCard(services: widget.services),
            const SizedBox(height: 18),
            _PromoBox(
              controller: promoController,
              errorText: promoError,
              appliedCode: appliedCode,
              onApply: applyPromo,
              onClear: clearPromo,
            ),
            const SizedBox(height: 18),
            _PriceBox(
              subtotal: widget.totalPrice,
              discountAmount: discountAmount,
              finalTotal: finalTotal,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PaymentQrScreen(
                        room: widget.room,
                        roomTypeName: widget.roomTypeName,
                        user: widget.user,
                        services: widget.services,
                        stayRange: widget.stayRange,
                        nights: widget.nights,
                        guests: widget.guests,
                        totalPrice: finalTotal,
                        discountCode: appliedCode,
                        discountAmount: discountAmount,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Continue to payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void applyPromo() {
    final code = promoController.text.trim().toUpperCase();
    final rate = _discountRate(code);
    setState(() {
      if (code.isEmpty) {
        promoError = 'Please enter a discount code';
        appliedCode = null;
        discountRate = 0;
      } else if (rate == 0) {
        promoError = 'Invalid discount code';
        appliedCode = null;
        discountRate = 0;
      } else {
        promoError = null;
        appliedCode = code;
        discountRate = rate;
      }
    });
  }

  void clearPromo() {
    setState(() {
      promoController.clear();
      promoError = null;
      appliedCode = null;
      discountRate = 0;
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;
  final DateTimeRange? stayRange;
  final int nights;
  final int guests;

  const _SummaryCard({
    required this.room,
    required this.roomTypeName,
    required this.stayRange,
    required this.nights,
    required this.guests,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room ${room.roomNumber}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roomTypeName,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _InfoLine(
            icon: Icons.calendar_today_outlined,
            label: stayRange == null
                ? 'No dates selected'
                : '${_formatDate(stayRange!.start)} - ${_formatDate(stayRange!.end)}',
            value: '$nights night${nights > 1 ? 's' : ''}',
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.people_outline,
            label: 'Guests',
            value: '$guests',
          ),
        ],
      ),
    );
  }
}

class _ServicesCard extends StatelessWidget {
  final List<BookingServiceModel> services;

  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const Text(
              'No add-on services',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PriceLine(
                  label: service.name,
                  value: '${_formatNumber(_parsePrice(service.price))} VND',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoBox extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final String? appliedCode;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _PromoBox({
    required this.controller,
    required this.errorText,
    required this.appliedCode,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discount code',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    errorText: errorText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: appliedCode == null ? onApply : onClear,
                  child: Text(appliedCode == null ? 'Apply' : 'Clear'),
                ),
              ),
            ],
          ),
          if (appliedCode != null) ...[
            const SizedBox(height: 10),
            Text(
              '$appliedCode applied',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double finalTotal;

  const _PriceBox({
    required this.subtotal,
    required this.discountAmount,
    required this.finalTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _DarkPriceLine(
            label: 'Subtotal',
            value: '${_formatNumber(subtotal)} VND',
          ),
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _DarkPriceLine(
              label: 'Discount',
              value: '-${_formatNumber(discountAmount)} VND',
            ),
          ],
          const Divider(height: 22, color: Colors.white24),
          _DarkPriceLine(
            label: 'Total',
            value: '${_formatNumber(finalTotal)} VND',
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;

  const _PriceLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DarkPriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _DarkPriceLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: strong ? 1 : 0.68),
              fontSize: strong ? 16 : 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: strong ? 18 : 13,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

double _discountRate(String code) {
  return switch (code) {
    'WELCOME10' => 0.10,
    'HOTEL15' => 0.15,
    _ => 0,
  };
}

double _parsePrice(String value) => double.tryParse(value) ?? 0;

String _formatNumber(double number) {
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
