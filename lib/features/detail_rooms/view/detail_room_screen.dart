import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/booking_service_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/room_review_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../payment/view/payment_confirmation_screen.dart';

class DetailRoomScreen extends StatefulWidget {
  final int roomId;
  final String? imageUrl;
  final UserModel user;

  const DetailRoomScreen({
    super.key,
    required this.roomId,
    required this.user,
    this.imageUrl,
  });

  @override
  State<DetailRoomScreen> createState() => _DetailRoomScreenState();
}

class _DetailRoomScreenState extends State<DetailRoomScreen> {
  late Future<_DetailData> detailFuture;

  @override
  void initState() {
    super.initState();
    detailFuture = fetchDetailData();
  }

  Future<_DetailData> fetchDetailData() async {
    final room = await fetchRoomDetail();
    final services = await fetchServices();
    final roomTypes = await fetchRoomTypes();
    final reviews = await fetchReviews();
    final eligibleBookingId = await fetchEligibleBookingId();
    final roomTypeName = room.roomTypeName.isNotEmpty
        ? room.roomTypeName
        : roomTypes[room.roomTypeId] ?? '';
    return _DetailData(
      room: room,
      roomTypeName: roomTypeName,
      services: services,
      reviews: reviews,
      eligibleBookingId: eligibleBookingId,
    );
  }

  Future<RoomModel> fetchRoomDetail() async {
    final response = await apiClient.get(
      Uri.parse('${ApiEndpoints.room}/${widget.roomId}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch room: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body);
    final roomJson = switch (jsonData) {
      {'data': Map<String, dynamic> data} => data,
      Map<String, dynamic> data => data,
      _ => throw Exception('Invalid room detail response'),
    };

    return RoomModel.fromJson(roomJson);
  }

  Future<List<BookingServiceModel>> fetchServices() async {
    try {
      final response = await apiClient.get(Uri.parse(ApiEndpoints.service));
      if (response.statusCode != 200) return _fallbackServices;

      final jsonData = json.decode(response.body);
      final servicesJson = switch (jsonData) {
        {'data': List data} => data,
        {'results': List data} => data,
        List data => data,
        _ => const [],
      };

      final services = servicesJson
          .whereType<Map<String, dynamic>>()
          .map(BookingServiceModel.fromJson)
          .where((service) => service.availability)
          .toList();

      return services.isEmpty ? _fallbackServices : services;
    } catch (_) {
      return _fallbackServices;
    }
  }

  Future<Map<int, String>> fetchRoomTypes() async {
    try {
      final response = await apiClient.get(Uri.parse(ApiEndpoints.roomTypes));
      if (response.statusCode != 200) return const {};

      final jsonData = json.decode(response.body);
      final roomTypesJson = switch (jsonData) {
        {'data': List data} => data,
        {'results': List data} => data,
        List data => data,
        _ => const [],
      };

      return {
        for (final item in roomTypesJson.whereType<Map<String, dynamic>>())
          if (_roomTypeId(item) != 0 && _roomTypeName(item).isNotEmpty)
            _roomTypeId(item): _roomTypeName(item),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<List<RoomReviewModel>> fetchReviews() async {
    try {
      final response = await apiClient.get(
        Uri.parse(ApiEndpoints.reviewsByRoom(widget.roomId)),
      );
      if (response.statusCode != 200) return const [];

      final jsonData = json.decode(response.body);
      final reviewsJson = switch (jsonData) {
        {'data': List data} => data,
        {'results': List data} => data,
        List data => data,
        _ => const [],
      };

      return reviewsJson
          .whereType<Map<String, dynamic>>()
          .map(RoomReviewModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<int?> fetchEligibleBookingId() async {
    final userId = int.tryParse(widget.user.userId);
    if (userId == null) return null;

    try {
      final response = await apiClient.get(
        Uri.parse(
          ApiEndpoints.reviewEligibility(userId: userId, roomId: widget.roomId),
        ),
      );
      if (response.statusCode != 200) return null;

      final jsonData = json.decode(response.body);
      if (jsonData is! Map<String, dynamic> || jsonData['eligible'] != true) {
        return null;
      }
      return int.tryParse(jsonData['booking_id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        foregroundColor: const Color(0xFF171725),
        elevation: 0,
        title: const Text(
          'Room details',
          style: TextStyle(fontFamily: 'Jost', fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<_DetailData>(
        future: detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailError(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  detailFuture = fetchDetailData();
                });
              },
            );
          }

          return _DetailBody(
            room: snapshot.data!.room,
            roomTypeName: snapshot.data!.roomTypeName,
            services: snapshot.data!.services,
            reviews: snapshot.data!.reviews,
            eligibleBookingId: snapshot.data!.eligibleBookingId,
            imageUrl: widget.imageUrl,
            user: widget.user,
          );
        },
      ),
    );
  }
}

class _DetailData {
  final RoomModel room;
  final String roomTypeName;
  final List<BookingServiceModel> services;
  final List<RoomReviewModel> reviews;
  final int? eligibleBookingId;

  const _DetailData({
    required this.room,
    required this.roomTypeName,
    required this.services,
    required this.reviews,
    required this.eligibleBookingId,
  });
}

class _DetailBody extends StatefulWidget {
  final RoomModel room;
  final String roomTypeName;
  final List<BookingServiceModel> services;
  final List<RoomReviewModel> reviews;
  final int? eligibleBookingId;
  final String? imageUrl;
  final UserModel user;

  const _DetailBody({
    required this.room,
    required this.roomTypeName,
    required this.services,
    required this.reviews,
    required this.eligibleBookingId,
    required this.imageUrl,
    required this.user,
  });

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final selectedServices = <int>{};
  final guestController = TextEditingController(text: '1');
  DateTimeRange? stayRange;
  String? guestError;

  int get nights => stayRange?.duration.inDays ?? 1;
  int get guestCount => int.tryParse(guestController.text.trim()) ?? 0;
  bool get canBook =>
      widget.room.status == 'available' &&
      stayRange != null &&
      guestError == null;

  double get totalPrice {
    final serviceTotal = widget.services
        .where((service) => selectedServices.contains(service.serviceId))
        .fold<double>(0, (sum, service) => sum + _parsePrice(service.price));

    return (_parsePrice(widget.room.pricePerNight) * nights) + serviceTotal;
  }

  List<BookingServiceModel> get chosenServices {
    return widget.services
        .where((service) => selectedServices.contains(service.serviceId))
        .toList();
  }

  @override
  void dispose() {
    guestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoomHero(
            room: widget.room,
            roomTypeName: widget.roomTypeName,
            imageUrl: widget.imageUrl,
          ),
          const SizedBox(height: 18),
          _RoomFacts(room: widget.room, roomTypeName: widget.roomTypeName),
          const SizedBox(height: 24),
          _StayPicker(
            stayRange: stayRange,
            nights: nights,
            onTap: pickStayRange,
          ),
          const SizedBox(height: 16),
          _GuestInput(
            controller: guestController,
            maxGuests: widget.room.maxGuests,
            errorText: guestError,
            onChanged: validateGuests,
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Description',
            trailing: '${_formatPrice(widget.room.pricePerNight)} VND/night',
          ),
          const SizedBox(height: 10),
          Text(
            widget.room.description.isEmpty
                ? 'No description available.'
                : widget.room.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          _ReviewsSection(
            reviews: widget.reviews,
            eligibleBookingId: widget.eligibleBookingId,
            roomId: widget.room.roomId,
            user: widget.user,
          ),
          const SizedBox(height: 26),
          const _SectionTitle(title: 'Add-on services'),
          const SizedBox(height: 12),
          ...widget.services.map((service) {
            final selected = selectedServices.contains(service.serviceId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ServiceTile(
                service: service,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      selectedServices.remove(service.serviceId);
                    } else {
                      selectedServices.add(service.serviceId);
                    }
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 12),
          _TotalBox(
            roomPrice: widget.room.pricePerNight,
            nights: nights,
            serviceCount: selectedServices.length,
            totalPrice: totalPrice,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: canBook
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PaymentConfirmationScreen(
                            room: widget.room,
                            roomTypeName: widget.roomTypeName,
                            user: widget.user,
                            services: chosenServices,
                            stayRange: stayRange,
                            nights: nights,
                            guests: guestCount,
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Book Now'),
            ),
          ),
          if (widget.room.status == 'available' && stayRange == null) ...[
            const SizedBox(height: 10),
            const Text(
              'Please choose check-in and check-out dates before booking',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> pickStayRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      initialDateRange:
          stayRange ??
          DateTimeRange(start: today, end: today.add(const Duration(days: 1))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (range == null || range.duration.inDays < 1) return;
    setState(() => stayRange = range);
  }

  void validateGuests(String value) {
    final guests = int.tryParse(value.trim()) ?? 0;
    setState(() {
      if (guests < 1) {
        guestError = 'Please enter at least 1 guest';
      } else if (guests > widget.room.maxGuests) {
        guestError = 'This room allows maximum ${widget.room.maxGuests} guests';
      } else {
        guestError = null;
      }
    });
  }
}

class _ReviewsSection extends StatefulWidget {
  final List<RoomReviewModel> reviews;
  final int? eligibleBookingId;
  final int roomId;
  final UserModel user;

  const _ReviewsSection({
    required this.reviews,
    required this.eligibleBookingId,
    required this.roomId,
    required this.user,
  });

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final commentController = TextEditingController();
  late List<RoomReviewModel> reviews;
  late int? eligibleBookingId;
  int selectedRating = 0;
  bool showComposer = false;
  bool isSubmitting = false;
  String? submitError;

  @override
  void initState() {
    super.initState();
    reviews = List.of(widget.reviews);
    eligibleBookingId = widget.eligibleBookingId;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle(title: 'Guest reviews')),
            if (eligibleBookingId != null && !showComposer)
              TextButton.icon(
                onPressed: () => setState(() => showComposer = true),
                icon: const Icon(Icons.rate_review_outlined, size: 19),
                label: const Text('Write a review'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (showComposer) ...[
          _ReviewComposer(
            rating: selectedRating,
            commentController: commentController,
            isSubmitting: isSubmitting,
            errorText: submitError,
            onRatingChanged: (rating) {
              setState(() {
                selectedRating = rating;
                submitError = null;
              });
            },
            onCancel: () {
              setState(() {
                showComposer = false;
                submitError = null;
              });
            },
            onSubmit: submitReview,
          ),
          const SizedBox(height: 14),
        ],
        if (reviews.isEmpty)
          const _EmptyReviews()
        else ...[
          _ReviewSummary(
            averageRating: averageRating,
            reviewCount: reviews.length,
          ),
          const SizedBox(height: 14),
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewTile(review: review),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> submitReview() async {
    final bookingId = eligibleBookingId;
    final userId = int.tryParse(widget.user.userId);
    final comment = commentController.text.trim();

    if (selectedRating == 0) {
      setState(() => submitError = 'Please select a rating');
      return;
    }
    if (comment.isEmpty) {
      setState(() => submitError = 'Please share your experience');
      return;
    }
    if (bookingId == null || userId == null || isSubmitting) return;

    setState(() {
      isSubmitting = true;
      submitError = null;
    });

    try {
      final response = await apiClient.post(
        Uri.parse(ApiEndpoints.review),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'room_id': widget.roomId,
          'booking_id': bookingId,
          'rating': selectedRating,
          'comment': comment,
        }),
      );

      final jsonData = json.decode(response.body);
      if (response.statusCode != 201 || jsonData is! Map<String, dynamic>) {
        throw Exception(_reviewResponseMessage(jsonData));
      }

      final review = RoomReviewModel.fromJson(jsonData);
      if (!mounted) return;
      setState(() {
        reviews.insert(0, review);
        eligibleBookingId = null;
        showComposer = false;
        selectedRating = 0;
        commentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => submitError = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}

class _ReviewComposer extends StatelessWidget {
  final int rating;
  final TextEditingController commentController;
  final bool isSubmitting;
  final String? errorText;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _ReviewComposer({
    required this.rating,
    required this.commentController,
    required this.isSubmitting,
    required this.errorText,
    required this.onRatingChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How was your stay?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: isSubmitting ? null : () => onRatingChanged(value),
                tooltip: '$value star${value > 1 ? 's' : ''}',
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
              hintText: 'Share what you liked about this room',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isSubmitting ? null : onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: const Text('Submit review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  final double averageRating;
  final int reviewCount;

  const _ReviewSummary({
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RatingStars(rating: averageRating),
                const SizedBox(height: 5),
                Text(
                  '$reviewCount verified review${reviewCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RoomReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final initial = review.reviewerName.characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _formatReviewDate(review.createdAt!),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              _RatingStars(rating: review.rating.toDouble(), compact: true),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              review.comment,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double rating;
  final bool compact;

  const _RatingStars({required this.rating, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final icon = rating >= value
            ? Icons.star_rounded
            : rating >= value - 0.5
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        return Icon(icon, size: compact ? 16 : 20, color: AppColors.warning);
      }),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.rate_review_outlined, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No reviews yet for this room.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestInput extends StatelessWidget {
  final TextEditingController controller;
  final int maxGuests;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _GuestInput({
    required this.controller,
    required this.maxGuests,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Guests',
        hintText: 'Enter number of guests',
        errorText: errorText,
        prefixIcon: const Icon(Icons.people_outline),
        suffixText: 'Max $maxGuests',
      ),
    );
  }
}

class _StayPicker extends StatelessWidget {
  final DateTimeRange? stayRange;
  final int nights;
  final VoidCallback onTap;

  const _StayPicker({
    required this.stayRange,
    required this.nights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stay dates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.edit_calendar_outlined, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: 'Check-in',
                    value: stayRange == null
                        ? 'Select date'
                        : _formatDate(stayRange!.start),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateBox(
                    label: 'Check-out',
                    value: stayRange == null
                        ? 'Select date'
                        : _formatDate(stayRange!.end),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stayRange == null
                  ? 'Tap to choose check-in and check-out'
                  : '$nights night${nights > 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;

  const _DateBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomHero extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;
  final String? imageUrl;

  const _RoomHero({
    required this.room,
    required this.roomTypeName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: AspectRatio(
          aspectRatio: 1.05,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl == null
                  ? const _RoomImagePlaceholder()
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _RoomImagePlaceholder();
                      },
                    ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(status: room.status),
                    const SizedBox(height: 10),
                    Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      roomTypeName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final BookingServiceModel service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _serviceIcon(service.name),
                color: selected ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatPrice(service.price)} VND',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.hint,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final String roomPrice;
  final int nights;
  final int serviceCount;
  final double totalPrice;

  const _TotalBox({
    required this.roomPrice,
    required this.nights,
    required this.serviceCount,
    required this.totalPrice,
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
          _TotalLine(
            label: 'Room x $nights night${nights > 1 ? 's' : ''}',
            value: '${_formatNumber(_parsePrice(roomPrice) * nights)} VND',
          ),
          const SizedBox(height: 8),
          _TotalLine(label: 'Services', value: '$serviceCount selected'),
          const Divider(height: 22, color: Colors.white24),
          _TotalLine(
            label: 'Total',
            value: '${_formatNumber(totalPrice)} VND',
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _TotalLine({
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

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EAEC),
      alignment: Alignment.center,
      child: const Icon(Icons.hotel, size: 40),
    );
  }
}

class _RoomFacts extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;

  const _RoomFacts({required this.room, required this.roomTypeName});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _Fact(icon: Icons.layers_outlined, text: 'Floor ${room.floor}'),
        _Fact(icon: Icons.people_outline, text: '${room.maxGuests} guests'),
        _Fact(icon: Icons.bed_outlined, text: '${room.bedCount} beds'),
        _Fact(icon: Icons.meeting_room_outlined, text: roomTypeName),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'available' => const Color(0xFF1A9C5B),
      'booked' => const Color(0xFFF59E0B),
      'maintenance' => const Color(0xFFF41F52),
      _ => const Color(0xFF78828A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'Jost',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatPrice(String value) {
  return _formatNumber(_parsePrice(value));
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

String _formatReviewDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _reviewResponseMessage(dynamic jsonData) {
  if (jsonData is Map<String, dynamic>) {
    return (jsonData['message'] ?? jsonData['error'])?.toString() ??
        'Unable to submit review';
  }
  return 'Unable to submit review';
}

int _roomTypeId(Map<String, dynamic> json) {
  return int.tryParse(
        (json['room_type_id'] ?? json['id'] ?? json['type_id'])?.toString() ??
            '',
      ) ??
      0;
}

String _roomTypeName(Map<String, dynamic> json) {
  return (json['room_type_name'] ?? json['name'] ?? json['type_name'])
          ?.toString() ??
      '';
}

IconData _serviceIcon(String name) {
  final text = name.toLowerCase();
  if (text.contains('breakfast') || text.contains('dinner')) {
    return Icons.restaurant_outlined;
  }
  if (text.contains('airport')) return Icons.local_taxi_outlined;
  if (text.contains('spa')) return Icons.spa_outlined;
  if (text.contains('bar')) return Icons.local_bar_outlined;
  if (text.contains('laundry')) return Icons.local_laundry_service_outlined;
  return Icons.room_service_outlined;
}

const _fallbackServices = [
  BookingServiceModel(
    serviceId: 2,
    serviceCode: 'SV002',
    name: 'Breakfast',
    price: '100000.00',
    availability: true,
    description: 'Buffet breakfast',
  ),
  BookingServiceModel(
    serviceId: 3,
    serviceCode: 'SV003',
    name: 'Airport Pickup',
    price: '200000.00',
    availability: true,
    description: 'Pickup from airport',
  ),
  BookingServiceModel(
    serviceId: 4,
    serviceCode: 'SV004',
    name: 'Spa',
    price: '300000.00',
    availability: true,
    description: 'Relaxing massage and spa',
  ),
  BookingServiceModel(
    serviceId: 5,
    serviceCode: 'SV005',
    name: 'Dinner',
    price: '250000.00',
    availability: true,
    description: 'Dinner buffet at restaurant',
  ),
  BookingServiceModel(
    serviceId: 6,
    serviceCode: 'SV006',
    name: 'Mini Bar',
    price: '150000.00',
    availability: true,
    description: 'In-room mini bar',
  ),
  BookingServiceModel(
    serviceId: 1,
    serviceCode: 'SV001',
    name: 'Laundry',
    price: '55000.00',
    availability: true,
    description: 'Laundry and ironing service',
  ),
];
