import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/booked_range_model.dart';
import '../../../core/models/booking_service_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/room_review_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../payment/view/payment_confirmation_screen.dart';
import 'widgets/booked_date_range_picker.dart';

class DetailRoomScreen extends StatefulWidget {
  final int roomId;
  final String? imageUrl;
  final UserModel user;
  final ValueChanged<UserModel> onUserUpdated;

  const DetailRoomScreen({
    super.key,
    required this.roomId,
    required this.user,
    required this.onUserUpdated,
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
      if (response.statusCode != 200) return const [];

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

      return services;
    } catch (_) {
      return const [];
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
    return FutureBuilder<_DetailData>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room details')),
            body: _DetailError(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  detailFuture = fetchDetailData();
                });
              },
            ),
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
          onUserUpdated: widget.onUserUpdated,
        );
      },
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
  final ValueChanged<UserModel> onUserUpdated;

  const _DetailBody({
    required this.room,
    required this.roomTypeName,
    required this.services,
    required this.reviews,
    required this.eligibleBookingId,
    required this.imageUrl,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final selectedServices = <int>{};
  final guestController = TextEditingController(text: '1');
  List<BookedRangeModel> bookedRanges = const [];
  DateTimeRange? stayRange;
  String? guestError;
  bool descriptionExpanded = false;
  bool isLoadingBookedRanges = false;

  int get nights => stayRange?.duration.inDays ?? 1;
  int get guestCount => int.tryParse(guestController.text.trim()) ?? 0;
  double get averageRating {
    if (widget.reviews.isEmpty) return 0;
    final total = widget.reviews.fold<int>(
      0,
      (sum, review) => sum + review.rating,
    );
    return total / widget.reviews.length;
  }

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
    final description = widget.room.description.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        title: const Text(
          'Room Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _RoomHero(imageUrl: widget.imageUrl),
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFEFE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoomHeading(
                      room: widget.room,
                      roomTypeName: widget.roomTypeName,
                      averageRating: averageRating,
                      reviewCount: widget.reviews.length,
                    ),
                    const SizedBox(height: 24),
                    _RoomFacts(
                      room: widget.room,
                      roomTypeName: widget.roomTypeName,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionTitle(title: 'Description'),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        maxLines: descriptionExpanded ? null : 4,
                        overflow: descriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF66707A),
                          fontSize: 14,
                          height: 1.57,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (description.length > 180)
                        TextButton(
                          onPressed: () {
                            setState(
                              () => descriptionExpanded = !descriptionExpanded,
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            descriptionExpanded ? 'Show Less' : 'Read More',
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Your stay'),
                    const SizedBox(height: 12),
                    _StayPicker(
                      stayRange: stayRange,
                      nights: nights,
                      isLoading: isLoadingBookedRanges,
                      hasBookedDates: bookedRanges.isNotEmpty,
                      onTap: pickStayRange,
                    ),
                    const SizedBox(height: 14),
                    _GuestInput(
                      controller: guestController,
                      maxGuests: widget.room.maxGuests,
                      errorText: guestError,
                      onChanged: validateGuests,
                    ),
                    if (widget.services.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionTitle(title: 'Add-on services'),
                      const SizedBox(height: 12),
                      ...widget.services.map((service) {
                        final selected = selectedServices.contains(
                          service.serviceId,
                        );
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
                    ],
                    const SizedBox(height: 18),
                    _TotalBox(
                      roomPrice: widget.room.pricePerNight,
                      nights: nights,
                      serviceCount: selectedServices.length,
                      totalPrice: totalPrice,
                    ),
                    const SizedBox(height: 28),
                    _ReviewsSection(
                      reviews: widget.reviews,
                      eligibleBookingId: widget.eligibleBookingId,
                      roomId: widget.room.roomId,
                      user: widget.user,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BookingBar(
        price: stayRange == null
            ? _parsePrice(widget.room.pricePerNight)
            : totalPrice,
        priceLabel: stayRange == null ? 'Price / night' : 'Total',
        enabled: widget.room.status == 'available',
        onPressed: bookNow,
      ),
    );
  }

  void bookNow() {
    if (stayRange == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please select check-in and check-out dates'),
          ),
        );
      return;
    }

    validateGuests(guestController.text);
    if (guestError != null || widget.room.status != 'available') return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          room: widget.room,
          roomTypeName: widget.roomTypeName,
          user: widget.user,
          onUserUpdated: widget.onUserUpdated,
          services: chosenServices,
          stayRange: stayRange,
          nights: nights,
          guests: guestCount,
          imageUrl: widget.imageUrl,
        ),
      ),
    );
  }

  Future<void> pickStayRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(today.year + 1, today.month, today.day);
    if (!await loadBookedRanges(today, lastDate)) return;
    if (!mounted) return;

    final currentRange = stayRange;
    final range = await showBookedDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: lastDate,
      bookedRanges: bookedRanges,
      initialDateRange:
          currentRange != null && !overlapsBookedRange(currentRange)
          ? currentRange
          : null,
    );

    if (range == null || range.duration.inDays < 1) return;
    if (overlapsBookedRange(range)) {
      showMessage('The selected stay includes dates that are already booked.');
      return;
    }
    setState(() => stayRange = range);
  }

  Future<bool> loadBookedRanges(DateTime from, DateTime to) async {
    if (isLoadingBookedRanges) return false;
    setState(() => isLoadingBookedRanges = true);

    try {
      final response = await apiClient.get(
        ApiEndpoints.roomBookedRanges(
          roomId: widget.room.roomId,
          from: from,
          to: to.add(const Duration(days: 1)),
        ),
      );
      final jsonData = json.decode(response.body);
      if (response.statusCode != 200) {
        final message = jsonData is Map<String, dynamic>
            ? (jsonData['error'] ?? jsonData['message'])?.toString()
            : null;
        throw Exception(message ?? 'Unable to load booked dates');
      }
      if (jsonData is! Map<String, dynamic> ||
          jsonData['booked_ranges'] is! List) {
        throw const FormatException('Invalid booked ranges response');
      }

      final ranges = (jsonData['booked_ranges'] as List)
          .whereType<Map<String, dynamic>>()
          .map(BookedRangeModel.fromJson)
          .toList();
      if (!mounted) return false;
      setState(() => bookedRanges = ranges);
      return true;
    } catch (error) {
      if (mounted) {
        showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
      return false;
    } finally {
      if (mounted) setState(() => isLoadingBookedRanges = false);
    }
  }

  bool overlapsBookedRange(DateTimeRange range) {
    return overlapsDates(range.start, range.end);
  }

  bool overlapsDates(DateTime start, DateTime end) {
    return bookedRanges.any((range) => range.overlaps(start, end));
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF171725),
                          fontSize: 14,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFF171725),
                        fontSize: 12,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                if (review.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment,
                    style: const TextStyle(
                      color: Color(0xFF9CA4AB),
                      fontSize: 12,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double rating;

  const _RatingStars({required this.rating});

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
        return Icon(icon, size: 20, color: AppColors.warning);
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
  final bool isLoading;
  final bool hasBookedDates;
  final VoidCallback onTap;

  const _StayPicker({
    required this.stayRange,
    required this.nights,
    required this.isLoading,
    required this.hasBookedDates,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
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
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Stay dates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: AppColors.textMuted,
                  ),
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
            if (hasBookedDates) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.circle, size: 9, color: AppColors.danger),
                  SizedBox(width: 7),
                  Text(
                    'Booked dates are marked with red dots',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
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
  final String? imageUrl;

  const _RoomHero({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 360,
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
                  Colors.black.withValues(alpha: 0.52),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomHeading extends StatelessWidget {
  final RoomModel room;
  final String roomTypeName;
  final double averageRating;
  final int reviewCount;

  const _RoomHeading({
    required this.room,
    required this.roomTypeName,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room ${room.roomNumber}',
                style: const TextStyle(
                  color: Color(0xFF171725),
                  fontSize: 22,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hotel_outlined,
                        size: 18,
                        color: Color(0xFF9CA4AB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        roomTypeName,
                        style: const TextStyle(
                          color: Color(0xFF78828A),
                          fontSize: 13,
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (reviewCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${averageRating.toStringAsFixed(1)} ($reviewCount)',
                          style: const TextStyle(
                            color: Color(0xFF171725),
                            fontSize: 13,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _StatusBadge(status: room.status),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
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

class _BookingBar extends StatelessWidget {
  final double price;
  final String priceLabel;
  final bool enabled;
  final VoidCallback onPressed;

  const _BookingBar({
    required this.price,
    required this.priceLabel,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      color: Color(0xFFA7AEC1),
                      fontSize: 13,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_formatNumber(price)} VND',
                      style: const TextStyle(
                        color: Color(0xFF191D31),
                        fontSize: 22,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: enabled ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2852AF),
                  foregroundColor: const Color(0xFFFEFEFE),
                  disabledBackgroundColor: const Color(0xFFE3E9ED),
                  disabledForegroundColor: const Color(0xFF9CA4AB),
                  minimumSize: const Size(0, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  enabled ? 'Booking Now' : 'Unavailable',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w600,
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
          if (serviceCount > 0) ...[
            const SizedBox(height: 8),
            _TotalLine(label: 'Services', value: '$serviceCount selected'),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Room information'),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final width = (constraints.maxWidth - spacing * 3) / 4;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Fact(
                  width: width,
                  icon: Icons.layers_outlined,
                  text: 'Floor ${room.floor}',
                ),
                const SizedBox(width: spacing),
                _Fact(
                  width: width,
                  icon: Icons.people_outline,
                  text: '${room.maxGuests} Guests',
                ),
                const SizedBox(width: spacing),
                _Fact(
                  width: width,
                  icon: Icons.bed_outlined,
                  text: '${room.bedCount} Beds',
                ),
                const SizedBox(width: spacing),
                _Fact(
                  width: width,
                  icon: Icons.meeting_room_outlined,
                  text: roomTypeName,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final double width;
  final IconData icon;
  final String text;

  const _Fact({required this.width, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F1FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF78828A),
              fontSize: 12,
              height: 1.30,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
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
