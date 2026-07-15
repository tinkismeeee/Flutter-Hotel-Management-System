import 'package:flutter/material.dart';

import '../../models/rating.dart';
import '../../services/rating_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'edit_rating_screen.dart';

class RatingListScreen extends StatefulWidget {
  const RatingListScreen({super.key});

  @override
  State<RatingListScreen> createState() => _RatingListScreenState();
}

class _RatingListScreenState extends State<RatingListScreen> {
  late Future<List<HotelRating>> ratingFuture;
  String searchQuery = '';
  String sortBy = 'newest';
  String filterBy = 'all';

  @override
  void initState() {
    super.initState();
    ratingFuture = RatingService.getRatings();
  }

  void refreshData() {
    setState(() {
      ratingFuture = RatingService.getRatings();
    });
  }

  List<HotelRating> applyQuery(List<HotelRating> ratings) {
    final query = searchQuery.trim().toLowerCase();
    final result = ratings.where((rating) {
      final matchesSearch =
          query.isEmpty ||
          customerLabel(rating).toLowerCase().contains(query) ||
          roomLabel(rating).toLowerCase().contains(query) ||
          rating.comment.toLowerCase().contains(query) ||
          rating.bookingId.toString().contains(query);
      final matchesFilter =
          filterBy == 'all' || rating.rating.toString() == filterBy;
      return matchesSearch && matchesFilter;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'rating_high') return b.rating.compareTo(a.rating);
      if (sortBy == 'rating_low') return a.rating.compareTo(b.rating);
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  Future<void> goToEdit(HotelRating ratingReview) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRatingScreen(ratingReview: ratingReview),
      ),
    );
    refreshData();
  }

  String shortDate(String value) {
    if (value.isEmpty) return '';
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  String customerLabel(HotelRating ratingReview) {
    if (ratingReview.userName.isNotEmpty) return ratingReview.userName;
    return 'Khách hàng #${ratingReview.userId}';
  }

  String roomLabel(HotelRating ratingReview) {
    if (ratingReview.roomNumber.isNotEmpty) {
      return 'Phòng ${ratingReview.roomNumber}';
    }
    return 'Phòng #${ratingReview.roomId}';
  }

  Widget starRow(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: AppColors.gold,
          size: 19,
        );
      }),
    );
  }

  Widget ratingCard(HotelRating ratingReview) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            child: const Icon(Icons.star_rate_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerLabel(ratingReview),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    starRow(ratingReview.rating),
                    const SizedBox(width: 8),
                    Text(
                      '${ratingReview.rating}/5',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${roomLabel(ratingReview)} · Booking #${ratingReview.bookingId}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                if (shortDate(ratingReview.createdAt).isNotEmpty)
                  Text(
                    'Ngày đánh giá: ${shortDate(ratingReview.createdAt)}',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                const SizedBox(height: 5),
                Text(
                  ratingReview.comment.isEmpty
                      ? 'Không có bình luận'
                      : ratingReview.comment,
                  style: const TextStyle(color: AppColors.textDark),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => goToEdit(ratingReview),
            icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
              'Quản lý đánh giá',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget ratingList(List<HotelRating> ratings) {
    final filtered = applyQuery(ratings);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListQueryBar(
          searchHint: 'Tìm khách, phòng, nội dung...',
          onSearchChanged: (value) => setState(() => searchQuery = value),
          sortValue: sortBy,
          sortOptions: const {
            'newest': 'Mới nhất',
            'rating_high': 'Điểm cao nhất',
            'rating_low': 'Điểm thấp nhất',
          },
          onSortChanged: (value) => setState(() => sortBy = value ?? 'newest'),
          filterValue: filterBy,
          filterOptions: const {
            'all': 'Tất cả số sao',
            '5': '5 sao',
            '4': '4 sao',
            '3': '3 sao',
            '2': '2 sao',
            '1': '1 sao',
          },
          onFilterChanged: (value) => setState(() => filterBy = value ?? 'all'),
          resultCount: filtered.length,
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Center(child: Text('Không có đánh giá phù hợp'))
        else
          ...filtered.map(ratingCard),
      ],
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
              child: FutureBuilder<List<HotelRating>>(
                future: ratingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                    );
                  }

                  return ratingList(snapshot.data ?? []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
