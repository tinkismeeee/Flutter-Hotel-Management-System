import 'package:flutter/material.dart';
import '../../models/hotel_service.dart';
import '../../services/hotel_service_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  late Future<List<HotelService>> serviceFuture;
  String searchQuery = '';
  String sortBy = 'name';
  String filterBy = 'all';

  @override
  void initState() {
    super.initState();
    serviceFuture = HotelServiceService.getServices();
  }

  void refreshData() {
    setState(() {
      serviceFuture = HotelServiceService.getServices();
    });
  }

  List<HotelService> applyQuery(List<HotelService> services) {
    final query = searchQuery.trim().toLowerCase();
    final result = services.where((service) {
      final matchesSearch =
          query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.serviceCode.toLowerCase().contains(query) ||
          service.description.toLowerCase().contains(query);
      final matchesFilter =
          filterBy == 'all' ||
          (filterBy == 'available' && service.availability) ||
          (filterBy == 'unavailable' && !service.availability);
      return matchesSearch && matchesFilter;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'price_high') return b.price.compareTo(a.price);
      if (sortBy == 'price_low') return a.price.compareTo(b.price);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddServiceScreen()),
    );
    refreshData();
  }

  Future<void> goToEdit(HotelService service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditServiceScreen(service: service)),
    );
    refreshData();
  }

  Future<void> confirmDelete(HotelService service) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa dịch vụ ${service.name} không?'),
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
      final success = await HotelServiceService.deleteService(
        service.serviceId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Xóa dịch vụ thành công' : 'Xóa dịch vụ thất bại',
          ),
        ),
      );

      if (success) refreshData();
    }
  }

  Widget serviceCard(HotelService service) {
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
            child: const Icon(
              Icons.room_service_rounded,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  service.serviceCode,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.price.toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  service.description,
                  style: const TextStyle(color: AppColors.textGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  service.availability ? 'Khả dụng' : 'Không khả dụng',
                  style: TextStyle(
                    color: service.availability
                        ? Colors.green
                        : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () => goToEdit(service),
                icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
              ),
              IconButton(
                onPressed: () => confirmDelete(service),
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
                      'Quản lý dịch vụ',
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
              child: FutureBuilder<List<HotelService>>(
                future: serviceFuture,
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

                  final allServices = snapshot.data ?? [];
                  final services = applyQuery(allServices);

                  if (allServices.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có dịch vụ',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListQueryBar(
                        searchHint: 'Tìm tên, mã dịch vụ...',
                        onSearchChanged: (value) =>
                            setState(() => searchQuery = value),
                        sortValue: sortBy,
                        sortOptions: const {
                          'name': 'Tên A-Z',
                          'price_low': 'Giá thấp nhất',
                          'price_high': 'Giá cao nhất',
                        },
                        onSortChanged: (value) =>
                            setState(() => sortBy = value ?? 'name'),
                        filterValue: filterBy,
                        filterOptions: const {
                          'all': 'Tất cả',
                          'available': 'Khả dụng',
                          'unavailable': 'Không khả dụng',
                        },
                        onFilterChanged: (value) =>
                            setState(() => filterBy = value ?? 'all'),
                        resultCount: services.length,
                      ),
                      const SizedBox(height: 16),
                      if (services.isEmpty)
                        const Center(child: Text('Không có dịch vụ phù hợp'))
                      else
                        ...services.map(serviceCard),
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
