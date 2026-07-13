import 'package:flutter/material.dart';

import '../../../core/models/booking_service_model.dart';
import '../../../core/models/payos_payment_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/payment_controller.dart';
import 'payment_qr_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final RoomModel room;
  final String roomTypeName;
  final UserModel user;
  final List<BookingServiceModel> services;
  final DateTimeRange? stayRange;
  final int nights;
  final int guests;
  final String? imageUrl;

  const PaymentConfirmationScreen({
    super.key,
    required this.room,
    required this.roomTypeName,
    required this.user,
    required this.services,
    required this.stayRange,
    required this.nights,
    required this.guests,
    this.imageUrl,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final promoController = TextEditingController();
  final paymentController = PaymentController();
  String? promoError;
  String? paymentError;
  PromotionModel? appliedPromotion;
  bool isApplyingPromo = false;
  bool isCreatingPayment = false;

  double get roomTotal =>
      _parsePrice(widget.room.pricePerNight) * widget.nights;

  double get serviceTotal => widget.services.fold(
    0,
    (sum, service) => sum + _parsePrice(service.price),
  );

  double get subtotal => roomTotal + serviceTotal;

  double get discountAmount {
    final promotion = appliedPromotion;
    if (promotion == null) return 0;
    final discountBase = promotion.scope == 'room'
        ? roomTotal
        : promotion.scope == 'service'
        ? serviceTotal
        : subtotal;
    return (discountBase * promotion.discountValue / 100).roundToDouble();
  }

  double get finalTotal =>
      (subtotal - discountAmount).clamp(0, double.infinity).toDouble();

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        foregroundColor: const Color(0xFF171725),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF171725),
            fontSize: 18,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.09,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoomOverview(
              room: widget.room,
              roomTypeName: widget.roomTypeName,
              imageUrl: widget.imageUrl,
            ),
            const SizedBox(height: 24),
            _CheckoutPanel(
              room: widget.room,
              roomTypeName: widget.roomTypeName,
              phone: widget.user.phone.trim(),
              stayRange: widget.stayRange,
              nights: widget.nights,
              guests: widget.guests,
              services: widget.services,
              roomTotal: roomTotal,
              discountAmount: discountAmount,
              finalTotal: finalTotal,
            ),
            const SizedBox(height: 24),
            _PromoBox(
              controller: promoController,
              errorText: promoError,
              appliedCode: appliedPromotion?.code,
              isLoading: isApplyingPromo,
              onApply: applyPromo,
              onClear: clearPromo,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PaymentActionBar(
        errorText: paymentError,
        isLoading: isCreatingPayment,
        onPressed: createPayment,
      ),
    );
  }

  Future<void> applyPromo() async {
    final code = promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        promoError = 'Please enter a discount code';
        appliedPromotion = null;
      });
      return;
    }

    setState(() {
      isApplyingPromo = true;
      promoError = null;
    });
    try {
      final promotion = await paymentController.validatePromotion(code);
      if (!mounted) return;
      setState(() {
        appliedPromotion = promotion;
        promoController.text = promotion.code;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        appliedPromotion = null;
        promoError = _cleanError(error);
      });
    } finally {
      if (mounted) setState(() => isApplyingPromo = false);
    }
  }

  void clearPromo() {
    setState(() {
      promoController.clear();
      promoError = null;
      appliedPromotion = null;
    });
  }

  Future<void> createPayment() async {
    if (widget.stayRange == null) {
      setState(
        () => paymentError = 'Check-in and check-out dates are required',
      );
      return;
    }
    if (promoController.text.trim().isNotEmpty && appliedPromotion == null) {
      setState(() => promoError = 'Apply or clear this discount code first');
      return;
    }

    setState(() {
      isCreatingPayment = true;
      paymentError = null;
    });
    try {
      final payment = await paymentController.createPayment(
        user: widget.user,
        room: widget.room,
        checkIn: widget.stayRange!.start,
        checkOut: widget.stayRange!.end,
        guests: widget.guests,
        services: widget.services,
        promotionCode: appliedPromotion?.code,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentQrScreen(
            room: widget.room,
            user: widget.user,
            roomTypeName: widget.roomTypeName,
            services: widget.services,
            stayRange: widget.stayRange,
            nights: widget.nights,
            guests: widget.guests,
            payment: payment,
            discountCode: appliedPromotion?.code,
            discountAmount: discountAmount,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => paymentError = _cleanError(error));
    } finally {
      if (mounted) setState(() => isCreatingPayment = false);
    }
  }
}

class _RoomOverview extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;
  final String? imageUrl;

  const _RoomOverview({
    required this.room,
    required this.roomTypeName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final typeName = roomTypeName.trim().isNotEmpty
        ? roomTypeName.trim()
        : room.roomTypeName.trim();
    final hasImage = imageUrl?.trim().isNotEmpty == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl!,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const _RoomImagePlaceholder();
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room ${room.roomNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF171725),
                  fontSize: 20,
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
              ),
              if (typeName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.bed_outlined,
                      size: 16,
                      color: Color(0xFF9CA4AB),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        typeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9CA4AB),
                          fontSize: 12,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${_formatNumber(_parsePrice(room.pricePerNight))} VND',
                      style: const TextStyle(
                        color: Color(0xFF2852AF),
                        fontSize: 16,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const TextSpan(
                      text: ' /night',
                      style: TextStyle(
                        color: Color(0xFF171725),
                        fontSize: 14,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.57,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      color: const Color(0xFFECF1F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.hotel_outlined,
        color: Color(0xFF9CA4AB),
        size: 28,
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;
  final String phone;
  final DateTimeRange? stayRange;
  final int nights;
  final int guests;
  final List<BookingServiceModel> services;
  final double roomTotal;
  final double discountAmount;
  final double finalTotal;

  const _CheckoutPanel({
    required this.room,
    required this.roomTypeName,
    required this.phone,
    required this.stayRange,
    required this.nights,
    required this.guests,
    required this.services,
    required this.roomTotal,
    required this.discountAmount,
    required this.finalTotal,
  });

  @override
  Widget build(BuildContext context) {
    final typeName = roomTypeName.trim().isNotEmpty
        ? roomTypeName.trim()
        : room.roomTypeName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8EAEC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Your Booking'),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dates',
            value: stayRange == null
                ? 'Not selected'
                : _formatDateRange(stayRange!),
          ),
          _DetailRow(
            icon: Icons.people_outline,
            label: 'Guest',
            value: '$guests Guest${guests == 1 ? '' : 's'} (1 Room)',
          ),
          if (typeName.isNotEmpty)
            _DetailRow(
              icon: Icons.meeting_room_outlined,
              label: 'Room type',
              value: typeName,
            ),
          if (phone.isNotEmpty)
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phone,
            ),
          const Divider(height: 32, color: Color(0xFFBFC6CC)),
          const _PanelTitle('Price Details'),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Room ($nights night${nights == 1 ? '' : 's'})',
            value: '${_formatNumber(roomTotal)} VND',
          ),
          ...services.map(
            (service) => _PriceRow(
              label: service.name,
              value: '${_formatNumber(_parsePrice(service.price))} VND',
            ),
          ),
          if (discountAmount > 0)
            _PriceRow(
              label: 'Discount',
              value: '-${_formatNumber(discountAmount)} VND',
              valueColor: const Color(0xFF17A673),
            ),
          const Divider(height: 24, color: Color(0xFFE8EAEC)),
          _PriceRow(
            label: 'Total price',
            value: '${_formatNumber(finalTotal)} VND',
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String text;

  const _PanelTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF2852AF),
        fontSize: 14,
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF78828A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF171725),
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF171725),
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF171725),
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                height: strong ? 1.3 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF171725),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
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
  final bool isLoading;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _PromoBox({
    required this.controller,
    required this.errorText,
    required this.appliedCode,
    required this.isLoading,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isApplied = appliedCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Promo',
          style: TextStyle(
            color: Color(0xFF171725),
            fontSize: 16,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          readOnly: isApplied || isLoading,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) {
            if (!isApplied && !isLoading) onApply();
          },
          decoration: InputDecoration(
            hintText: 'Enter promotion code',
            errorText: errorText,
            filled: true,
            fillColor: const Color(0xFFECF1F6),
            prefixIcon: const Icon(
              Icons.local_offer_outlined,
              color: Color(0xFF2852AF),
            ),
            suffixIcon: SizedBox(
              width: 76,
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : isApplied
                    ? onClear
                    : onApply,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isApplied ? 'Clear' : 'Apply'),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE8EAEC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE8EAEC)),
            ),
          ),
        ),
        if (isApplied) ...[
          const SizedBox(height: 8),
          Text(
            '$appliedCode applied',
            style: const TextStyle(
              color: Color(0xFF17A673),
              fontSize: 13,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentActionBar extends StatelessWidget {
  final String? errorText;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PaymentActionBar({
    required this.errorText,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorText != null) ...[
              Text(
                errorText!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2852AF),
                  foregroundColor: const Color(0xFFFEFEFE),
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Select Payment',
                        style: TextStyle(
                          color: Color(0xFFFEFEFE),
                          fontSize: 16,
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.08,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _parsePrice(String value) => double.tryParse(value) ?? 0;

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

String _formatNumber(double number) {
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

String _formatDateRange(DateTimeRange range) {
  final start = range.start;
  final end = range.end;
  if (start.year == end.year && start.month == end.month) {
    return '${start.day} - ${end.day} ${_monthName(end.month)} ${end.year}';
  }
  return '${_formatShortDate(start)} - ${_formatShortDate(end)}';
}

String _formatShortDate(DateTime date) {
  return '${date.day} ${_monthName(date.month)} ${date.year}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
