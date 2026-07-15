import 'package:flutter/material.dart';
import '../../models/promotion.dart';
import '../../services/promotion_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'add_promotion_screen.dart';
import 'edit_promotion_screen.dart';

class PromotionListScreen extends StatefulWidget {
  const PromotionListScreen({super.key});

  @override
  State<PromotionListScreen> createState() => _PromotionListScreenState();
}

class _PromotionListScreenState extends State<PromotionListScreen> {
  late Future<List<Promotion>> promotionFuture;
  String searchQuery = '';
  String sortBy = 'newest';
  String filterBy = 'all';

  @override
  void initState() {
    super.initState();
    promotionFuture = PromotionService.getPromotions();
  }

  void refreshData() {
    setState(() {
      promotionFuture = PromotionService.getPromotions();
    });
  }

  List<Promotion> applyQuery(List<Promotion> promotions) {
    final query = searchQuery.trim().toLowerCase();
    final result = promotions.where((promotion) {
      final matchesSearch =
          query.isEmpty ||
          promotion.name.toLowerCase().contains(query) ||
          promotion.promotionCode.toLowerCase().contains(query) ||
          promotion.scope.toLowerCase().contains(query);
      final matchesFilter =
          filterBy == 'all' ||
          (filterBy == 'active' && promotion.isActive) ||
          (filterBy == 'inactive' && !promotion.isActive);
      return matchesSearch && matchesFilter;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'name') {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (sortBy == 'discount') {
        return b.discountValue.compareTo(a.discountValue);
      }
      return b.promotionId.compareTo(a.promotionId);
    });
    return result;
  }

  String shortDate(String value) {
    if (value.isEmpty) return '';
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPromotionScreen()),
    );
    refreshData();
  }

  Future<void> goToEdit(Promotion promotion) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPromotionScreen(promotion: promotion),
      ),
    );
    refreshData();
  }

  Future<void> confirmDelete(Promotion promotion) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa khuyến mãi ${promotion.name} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await PromotionService.deletePromotion(
        promotion.promotionId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Xóa khuyến mãi thành công' : 'Xóa khuyến mãi thất bại',
          ),
        ),
      );

      if (success) refreshData();
    }
  }

  Widget promotionCard(Promotion promotion) {
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
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            child: const Icon(Icons.discount_rounded, color: AppColors.gold),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  promotion.promotionCode,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giảm: ${promotion.discountValue.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  '${shortDate(promotion.startDate)} → ${shortDate(promotion.endDate)}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  'Scope: ${promotion.scope}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  promotion.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                  style: TextStyle(
                    color: promotion.isActive ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () => goToEdit(promotion),
                icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
              ),
              IconButton(
                onPressed: () => confirmDelete(promotion),
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: goToAdd,
        child: const Icon(Icons.add, color: AppColors.navy),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                      'Quản lý khuyến mãi',
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
            ),

            Expanded(
              child: FutureBuilder<List<Promotion>>(
                future: promotionFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  final allPromotions = snapshot.data ?? [];
                  final promotions = applyQuery(allPromotions);

                  if (allPromotions.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có khuyến mãi',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListQueryBar(
                        searchHint: 'Tìm tên, mã, phạm vi...',
                        onSearchChanged: (value) =>
                            setState(() => searchQuery = value),
                        sortValue: sortBy,
                        sortOptions: const {
                          'newest': 'Mới nhất',
                          'name': 'Tên A-Z',
                          'discount': 'Giảm giá cao nhất',
                        },
                        onSortChanged: (value) =>
                            setState(() => sortBy = value ?? 'newest'),
                        filterValue: filterBy,
                        filterOptions: const {
                          'all': 'Tất cả',
                          'active': 'Đang hoạt động',
                          'inactive': 'Ngừng hoạt động',
                        },
                        onFilterChanged: (value) =>
                            setState(() => filterBy = value ?? 'all'),
                        resultCount: promotions.length,
                      ),
                      const SizedBox(height: 16),
                      if (promotions.isEmpty)
                        const Center(child: Text('Không có khuyến mãi phù hợp'))
                      else
                        ...promotions.map(promotionCard),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
