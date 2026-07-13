import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/booking_service_model.dart';
import '../../../core/models/payos_payment_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../controller/payment_controller.dart';

class PaymentQrScreen extends StatefulWidget {
  final RoomModel room;
  final UserModel user;
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
    required this.user,
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
  final reviewCommentController = TextEditingController();
  late PayOsPaymentModel payment;
  Timer? statusTimer;
  bool isChecking = false;
  String? statusError;
  int reviewRating = 0;
  int? reviewBookingId;
  bool isReviewEligibilityLoading = false;
  bool reviewEligibilityLoaded = false;
  bool isSubmittingReview = false;
  bool reviewSubmitted = false;
  String? reviewError;

  bool get isPaid => payment.status.toLowerCase() == 'paid';
  bool get isCancelled =>
      ['cancelled', 'expired'].contains(payment.status.toLowerCase());

  @override
  void initState() {
    super.initState();
    payment = widget.payment;
    debugPrint(
      '[PAYOS][Flutter] qr-opened booking=${payment.bookingId} '
      'order=${payment.orderCode} amount=${payment.amount}',
    );
    statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkPaymentStatus(),
    );
    if (isPaid) unawaited(loadReviewEligibility());
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    reviewCommentController.dispose();
    debugPrint(
      '[PAYOS][Flutter] qr-closed booking=${payment.bookingId} status=${payment.status}',
    );
    super.dispose();
  }

  Future<void> checkPaymentStatus() async {
    if (isChecking || isPaid || isCancelled) return;
    isChecking = true;
    try {
      final previousStatus = payment.status;
      final latest = await paymentController.getPayment(payment.bookingId);
      if (!mounted) return;
      setState(() {
        payment = latest;
        statusError = null;
      });
      if (latest.status != previousStatus) {
        debugPrint(
          '[PAYOS][Flutter] payment-status-changed booking=${latest.bookingId} '
          '$previousStatus->${latest.status}',
        );
      }
      if (latest.status.toLowerCase() == 'paid' &&
          previousStatus.toLowerCase() != 'paid') {
        unawaited(loadReviewEligibility());
      }
      if (isPaid || isCancelled) {
        statusTimer?.cancel();
        debugPrint(
          '[PAYOS][Flutter] payment-terminal booking=${payment.bookingId} status=${payment.status}',
        );
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint(
        '[PAYOS][Flutter] payment-status-error booking=${payment.bookingId} '
        'message="${_cleanError(error)}"',
      );
      setState(() => statusError = _cleanError(error));
    } finally {
      isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
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
            const SizedBox(height: 14),
            _RoomDetailsPanel(room: widget.room),
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
            const SizedBox(height: 14),
            _PaymentDetailsPanel(payment: payment),
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
            if (isPaid) ...[
              const SizedBox(height: 20),
              _PaymentReviewSection(
                isLoading: isReviewEligibilityLoading,
                isEligible: reviewBookingId != null,
                eligibilityLoaded: reviewEligibilityLoaded,
                isSubmitting: isSubmittingReview,
                submitted: reviewSubmitted,
                rating: reviewRating,
                commentController: reviewCommentController,
                errorText: reviewError,
                onRetry: loadReviewEligibility,
                onRatingChanged: (rating) {
                  setState(() {
                    reviewRating = rating;
                    reviewError = null;
                  });
                },
                onSubmit: submitReview,
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

  Future<void> loadReviewEligibility() async {
    final userId = int.tryParse(widget.user.userId);
    if (userId == null || isReviewEligibilityLoading) return;

    setState(() {
      isReviewEligibilityLoading = true;
      reviewError = null;
    });
    try {
      final response = await apiClient.get(
        Uri.parse(
          ApiEndpoints.reviewEligibility(
            userId: userId,
            roomId: widget.room.roomId,
            bookingId: payment.bookingId,
          ),
        ),
      );
      final data = json.decode(response.body);
      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw Exception(_responseMessage(data, 'Cannot check review status'));
      }
      if (!mounted) return;
      setState(() {
        reviewBookingId = data['eligible'] == true
            ? int.tryParse(data['booking_id']?.toString() ?? '')
            : null;
        reviewEligibilityLoaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => reviewError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => isReviewEligibilityLoading = false);
      }
    }
  }

  Future<void> submitReview() async {
    final bookingId = reviewBookingId;
    final userId = int.tryParse(widget.user.userId);
    final comment = reviewCommentController.text.trim();
    if (reviewRating == 0) {
      setState(() => reviewError = 'Please select a rating');
      return;
    }
    if (comment.isEmpty) {
      setState(() => reviewError = 'Please share your experience');
      return;
    }
    if (bookingId == null || userId == null || isSubmittingReview) return;

    setState(() {
      isSubmittingReview = true;
      reviewError = null;
    });
    try {
      final response = await apiClient.post(
        Uri.parse(ApiEndpoints.review),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'room_id': widget.room.roomId,
          'booking_id': bookingId,
          'rating': reviewRating,
          'comment': comment,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode != 201) {
        throw Exception(_responseMessage(data, 'Unable to submit review'));
      }
      if (!mounted) return;
      setState(() {
        reviewBookingId = null;
        reviewSubmitted = true;
        reviewCommentController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => reviewError = _cleanError(error));
    } finally {
      if (mounted) setState(() => isSubmittingReview = false);
    }
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
              ' | $nights night${nights > 1 ? 's' : ''}'
              ' | $guests guest${guests > 1 ? 's' : ''}',
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

class _RoomDetailsPanel extends StatelessWidget {
  final RoomModel room;

  const _RoomDetailsPanel({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoomFact(
                icon: Icons.layers_outlined,
                text: 'Floor ${room.floor}',
              ),
              _RoomFact(
                icon: Icons.people_outline,
                text: 'Up to ${room.maxGuests} guests',
              ),
              _RoomFact(
                icon: Icons.bed_outlined,
                text: '${room.bedCount} beds',
              ),
              _RoomFact(
                icon: Icons.payments_outlined,
                text:
                    '${_formatNumber(_parsePrice(room.pricePerNight))} VND/night',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            room.description.isEmpty
                ? 'No room description available.'
                : room.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomFact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RoomFact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetailsPanel extends StatelessWidget {
  final PayOsPaymentModel payment;

  const _PaymentDetailsPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    final status = payment.status.toLowerCase();
    final statusColor = status == 'paid'
        ? AppColors.success
        : status == 'pending'
        ? AppColors.warning
        : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Booking ID', value: '#${payment.bookingId}'),
          const SizedBox(height: 10),
          _InfoRow(label: 'Order', value: payment.orderCode.toString()),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Payment status',
            value: payment.status.toUpperCase(),
            valueColor: statusColor,
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

class _PaymentReviewSection extends StatelessWidget {
  final bool isLoading;
  final bool isEligible;
  final bool eligibilityLoaded;
  final bool isSubmitting;
  final bool submitted;
  final int rating;
  final TextEditingController commentController;
  final String? errorText;
  final VoidCallback onRetry;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _PaymentReviewSection({
    required this.isLoading,
    required this.isEligible,
    required this.eligibilityLoaded,
    required this.isSubmitting,
    required this.submitted,
    required this.rating,
    required this.commentController,
    required this.errorText,
    required this.onRetry,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review_outlined, color: AppColors.primary),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Rate your stay',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading || (!eligibilityLoaded && errorText == null))
            const Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (submitted)
            const _ReviewMessage(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              text: 'Thank you. Your review has been submitted.',
            )
          else if (!eligibilityLoaded && errorText != null) ...[
            _ReviewMessage(
              icon: Icons.error_outline,
              color: AppColors.danger,
              text: errorText!,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ] else if (!isEligible)
            const _ReviewMessage(
              icon: Icons.verified_outlined,
              color: AppColors.textMuted,
              text: 'This booking has already been reviewed.',
            )
          else ...[
            const Text(
              'How was this room?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: isSubmitting ? null : () => onRatingChanged(value),
                  tooltip: '$value star${value == 1 ? '' : 's'}',
                  constraints: const BoxConstraints.tightFor(
                    width: 42,
                    height: 42,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    value <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              enabled: !isSubmitting,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Your review',
                hintText: 'Share your experience with this room',
                alignLabelWithHint: true,
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                errorText!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ReviewMessage({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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

String _responseMessage(dynamic data, String fallback) {
  if (data is Map<String, dynamic>) {
    return (data['message'] ?? data['error'])?.toString() ?? fallback;
  }
  return fallback;
}
