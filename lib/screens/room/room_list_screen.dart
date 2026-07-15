import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'add_room_screen.dart';
import 'edit_room_screen.dart';
import 'room_booking_schedule_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  late Future<List<Room>> roomFuture;
  String searchQuery = '';
  String sortBy = 'number';
  String filterBy = 'all';

  @override
  void initState() {
    super.initState();
    roomFuture = RoomService.getRooms();
  }

  void refreshData() {
    setState(() {
      roomFuture = RoomService.getRooms();
    });
  }

  List<Room> applyQuery(List<Room> rooms) {
    final query = searchQuery.trim().toLowerCase();
    final result = rooms.where((room) {
      final matchesSearch =
          query.isEmpty ||
          room.roomNumber.toLowerCase().contains(query) ||
          room.roomTypeName.toLowerCase().contains(query) ||
          room.floor.toString().contains(query);
      final matchesFilter =
          filterBy == 'all' || room.status.toLowerCase() == filterBy;
      return matchesSearch && matchesFilter;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'price_high') {
        return b.pricePerNight.compareTo(a.pricePerNight);
      }
      if (sortBy == 'price_low') {
        return a.pricePerNight.compareTo(b.pricePerNight);
      }
      return a.roomNumber.compareTo(b.roomNumber);
    });
    return result;
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRoomScreen()),
    );
    refreshData();
  }

  Future<void> goToEdit(Room room) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditRoomScreen(room: room)),
    );
    refreshData();
  }

  void openBookingSchedule(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomBookingScheduleScreen(room: room)),
    );
  }

  Future<void> confirmDelete(Room room) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa phòng ${room.roomNumber}?'),
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
      final success = await RoomService.deleteRoom(room.roomId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Xóa phòng thành công' : 'Xóa phòng thất bại',
          ),
        ),
      );

      if (success) refreshData();
    }
  }

  Widget roomCard(Room room) {
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
            child: const Icon(Icons.bed_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng ${room.roomNumber}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  room.roomTypeName.isEmpty
                      ? 'Loại phòng ID: ${room.roomTypeId}'
                      : room.roomTypeName,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tầng ${room.floor} • ${room.maxGuests} khách • ${room.bedCount} giường',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  '${room.pricePerNight.toStringAsFixed(0)} VNĐ / đêm',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  'Trạng thái: ${room.status}',
                  style: TextStyle(
                    color: room.status == 'available'
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
                tooltip: 'Xem lịch đặt',
                onPressed: () => openBookingSchedule(room),
                icon: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.blueAccent,
                ),
              ),
              IconButton(
                onPressed: () => goToEdit(room),
                icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
              ),
              IconButton(
                onPressed: () => confirmDelete(room),
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
                      'Quản lý phòng',
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
              child: FutureBuilder<List<Room>>(
                future: roomFuture,
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

                  final rooms = applyQuery(snapshot.data ?? []);

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListQueryBar(
                        searchHint: 'Tìm số phòng, loại phòng, tầng...',
                        onSearchChanged: (value) =>
                            setState(() => searchQuery = value),
                        sortValue: sortBy,
                        sortOptions: const {
                          'number': 'Số phòng',
                          'price_low': 'Giá thấp nhất',
                          'price_high': 'Giá cao nhất',
                        },
                        onSortChanged: (value) =>
                            setState(() => sortBy = value ?? 'number'),
                        filterValue: filterBy,
                        filterOptions: const {
                          'all': 'Tất cả',
                          'available': 'Còn trống',
                          'booked': 'Đã đặt',
                          'occupied': 'Đang ở',
                          'maintenance': 'Bảo trì',
                        },
                        onFilterChanged: (value) =>
                            setState(() => filterBy = value ?? 'all'),
                        resultCount: rooms.length,
                      ),
                      const SizedBox(height: 16),
                      if (rooms.isEmpty)
                        const Center(child: Text('Không có phòng phù hợp'))
                      else
                        ...rooms.map(roomCard),
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
