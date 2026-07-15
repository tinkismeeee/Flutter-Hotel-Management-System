import 'package:flutter/material.dart';

import '../../models/rating.dart';
import '../../services/rating_service.dart';
import '../../utils/app_colors.dart';

class EditRatingScreen extends StatefulWidget {
  final HotelRating ratingReview;

  const EditRatingScreen({super.key, required this.ratingReview});

  @override
  State<EditRatingScreen> createState() => _EditRatingScreenState();
}

class _EditRatingScreenState extends State<EditRatingScreen> {
  late TextEditingController commentController;
  late int selectedRating;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedRating = widget.ratingReview.rating.clamp(1, 5);
    commentController = TextEditingController(
      text: widget.ratingReview.comment,
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> updateRating() async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await RatingService.updateRating(
      id: widget.ratingReview.reviewId,
      rating: selectedRating,
      comment: commentController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Cập nhật đánh giá thành công'
              : 'Cập nhật đánh giá thất bại',
        ),
      ),
    );

    if (success) Navigator.pop(context);
  }

  String roomLabel() {
    if (widget.ratingReview.roomNumber.isNotEmpty) {
      return 'Phòng ${widget.ratingReview.roomNumber}';
    }
    return 'Phòng #${widget.ratingReview.roomId}';
  }

  String customerLabel() {
    if (widget.ratingReview.userName.isNotEmpty) {
      return widget.ratingReview.userName;
    }
    return 'Khách hàng #${widget.ratingReview.userId}';
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
              'Sửa đánh giá',
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

  Widget infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customerLabel(),
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${roomLabel()} · Booking #${widget.ratingReview.bookingId}',
            style: const TextStyle(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingPicker() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '$selectedRating/5',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() {
                    selectedRating = value;
                  });
                },
                icon: Icon(
                  value <= selectedRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.gold,
                  size: 34,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget commentField() {
    return TextField(
      controller: commentController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: 'Nội dung đánh giá',
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
                  ratingPicker(),
                  commentField(),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: isLoading ? null : updateRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Đang cập nhật...' : 'Cập nhật đánh giá',
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
