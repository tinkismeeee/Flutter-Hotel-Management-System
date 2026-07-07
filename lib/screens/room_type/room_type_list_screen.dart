import 'package:flutter/material.dart';
import '../../models/room_type.dart';
import '../../services/room_type_service.dart';
import '../../utils/app_colors.dart';
import 'add_room_type_screen.dart';
import 'edit_room_type_screen.dart';

class RoomTypeListScreen extends StatefulWidget {
  const RoomTypeListScreen({super.key});

  @override
  State<RoomTypeListScreen> createState() => _RoomTypeListScreenState();
}

class _RoomTypeListScreenState extends State<RoomTypeListScreen> {
  late Future<List<RoomType>> roomTypeFuture;

  @override
  void initState() {
    super.initState();
    roomTypeFuture = RoomTypeService.getRoomTypes();
  }

  void refreshData() {
    setState(() {
      roomTypeFuture = RoomTypeService.getRoomTypes();
    });
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddRoomTypeScreen(),
      ),
    );
    refreshData();
  }

  Future<void> goToEdit(RoomType roomType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRoomTypeScreen(roomType: roomType),
      ),
    );
    refreshData();
  }

  Future<void> confirmDelete(RoomType roomType) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa loại phòng ${roomType.name} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await RoomTypeService.deleteRoomType(
        roomType.roomTypeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Xóa loại phòng thành công'
                : 'Xóa loại phòng thất bại',
          ),
        ),
      );

      if (success) refreshData();
    }
  }

  Widget roomTypeCard(RoomType roomType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.gold.withOpacity(0.18),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomType.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${roomType.roomTypeId}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roomType.description,
                  style: const TextStyle(
                    color: AppColors.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () => goToEdit(roomType),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.gold,
                ),
              ),
              IconButton(
                onPressed: () => confirmDelete(roomType),
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Colors.redAccent,
                ),
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
        child: const Icon(
          Icons.add,
          color: AppColors.navy,
        ),
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.gold,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Quản lý loại phòng',
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
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<List<RoomType>>(
                future: roomTypeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                        ),
                      ),
                    );
                  }

                  final roomTypes = snapshot.data ?? [];

                  if (roomTypes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có loại phòng',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: roomTypes.length,
                    itemBuilder: (context, index) {
                      return roomTypeCard(roomTypes[index]);
                    },
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