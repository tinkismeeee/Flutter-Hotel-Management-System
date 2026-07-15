import 'package:flutter/material.dart';
import '../../models/staff.dart';
import '../../services/staff_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  late Future<List<Staff>> staffFuture;
  String searchQuery = '';
  String sortBy = 'name';
  String filterBy = 'all';

  @override
  void initState() {
    super.initState();
    staffFuture = StaffService.getStaffs();
  }

  void refreshData() {
    setState(() {
      staffFuture = StaffService.getStaffs();
    });
  }

  List<Staff> applyQuery(List<Staff> staffs) {
    final query = searchQuery.trim().toLowerCase();
    final result = staffs.where((staff) {
      final matchesSearch =
          query.isEmpty ||
          '${staff.firstName} ${staff.lastName}'.toLowerCase().contains(
            query,
          ) ||
          staff.username.toLowerCase().contains(query) ||
          staff.email.toLowerCase().contains(query) ||
          staff.phoneNumber.toLowerCase().contains(query);
      final matchesFilter =
          filterBy == 'all' ||
          (filterBy == 'active' && staff.isActive) ||
          (filterBy == 'inactive' && !staff.isActive);
      return matchesSearch && matchesFilter;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'newest') return b.userId.compareTo(a.userId);
      if (sortBy == 'email') return a.email.compareTo(b.email);
      return '${a.firstName} ${a.lastName}'.compareTo(
        '${b.firstName} ${b.lastName}',
      );
    });
    return result;
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
    );
    refreshData();
  }

  Future<void> goToEdit(Staff staff) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEmployeeScreen(staff: staff)),
    );
    refreshData();
  }

  Future<void> confirmDelete(Staff staff) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa ${staff.firstName} ${staff.lastName}?',
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
      final success = await StaffService.deleteStaff(staff.userId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Xóa thành công' : 'Xóa thất bại')),
      );

      if (success) refreshData();
    }
  }

  Widget staffCard(Staff staff) {
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
            radius: 27,
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            child: Text(
              staff.firstName.isNotEmpty ? staff.firstName[0] : '?',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${staff.firstName} ${staff.lastName}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.username,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.email,
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  staff.phoneNumber,
                  style: const TextStyle(color: AppColors.textGray),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () => goToEdit(staff),
                icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
              ),
              IconButton(
                onPressed: () => confirmDelete(staff),
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
              width: double.infinity,
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
                      'Quản lý nhân viên',
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
              child: FutureBuilder<List<Staff>>(
                future: staffFuture,
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

                  final staffs = applyQuery(snapshot.data ?? []);

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListQueryBar(
                        searchHint: 'Tìm tên, username, email...',
                        onSearchChanged: (value) =>
                            setState(() => searchQuery = value),
                        sortValue: sortBy,
                        sortOptions: const {
                          'name': 'Tên A-Z',
                          'email': 'Email A-Z',
                          'newest': 'Mới nhất',
                        },
                        onSortChanged: (value) =>
                            setState(() => sortBy = value ?? 'name'),
                        filterValue: filterBy,
                        filterOptions: const {
                          'all': 'Tất cả',
                          'active': 'Đang hoạt động',
                          'inactive': 'Đã khóa',
                        },
                        onFilterChanged: (value) =>
                            setState(() => filterBy = value ?? 'all'),
                        resultCount: staffs.length,
                      ),
                      const SizedBox(height: 16),
                      if (staffs.isEmpty)
                        const Center(child: Text('Không có nhân viên phù hợp'))
                      else
                        ...staffs.map(staffCard),
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
