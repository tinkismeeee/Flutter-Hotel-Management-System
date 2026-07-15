import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/room.dart';
import '../../services/booking_service.dart';
import '../../services/room_service.dart';
import '../../utils/app_colors.dart';
import 'room_detail_screen.dart';

class RoomInfoData {
  final List<Room> rooms;
  final List<Booking> bookings;

  const RoomInfoData({required this.rooms, required this.bookings});
}

class RoomInfoListScreen extends StatefulWidget {
  const RoomInfoListScreen({super.key});

  @override
  State<RoomInfoListScreen> createState() => _RoomInfoListScreenState();
}

class _RoomInfoListScreenState extends State<RoomInfoListScreen> {
  late Future<RoomInfoData> roomFuture;
  int? selectedRoomTypeId;
  int? selectedMinGuests;
  int? selectedMinBeds;
  double? selectedMinPrice;
  double? selectedMaxPrice;
  DateTimeRange? selectedDateRange;
  final Set<String> selectedStatuses = {};

  @override
  void initState() {
    super.initState();
    roomFuture = loadRoomInfo();
  }

  void refreshData() {
    setState(() {
      roomFuture = loadRoomInfo();
    });
  }

  Future<RoomInfoData> loadRoomInfo() async {
    final rooms = await RoomService.getRooms();
    final bookings = await loadBookingsSafely();

    return RoomInfoData(rooms: rooms, bookings: bookings);
  }

  Future<List<Booking>> loadBookingsSafely() async {
    try {
      return BookingService.getBookings();
    } catch (_) {
      return const [];
    }
  }

  void openRoomDetail(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)),
    );
  }

  String money(double value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Còn trống';
      case 'booked':
        return 'Đã đặt';
      case 'occupied':
        return 'Đang ở';
      case 'maintenance':
        return 'Bảo trì';
      default:
        return status.isEmpty ? 'Chưa rõ' : status;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'booked':
      case 'occupied':
        return Colors.orange;
      case 'maintenance':
        return Colors.redAccent;
      default:
        return AppColors.textGray;
    }
  }

  bool get hasActiveFilters {
    return selectedRoomTypeId != null ||
        selectedMinGuests != null ||
        selectedMinBeds != null ||
        selectedMinPrice != null ||
        selectedMaxPrice != null ||
        selectedDateRange != null ||
        selectedStatuses.isNotEmpty;
  }

  List<MapEntry<String, String>> get statusOptions {
    return const [
      MapEntry('available', 'Còn trống'),
      MapEntry('booked', 'Đã đặt'),
      MapEntry('occupied', 'Đang ở'),
      MapEntry('maintenance', 'Bảo trì'),
    ];
  }

  Map<int, String> roomTypeOptions(List<Room> rooms) {
    final options = <int, String>{};

    for (final room in rooms) {
      if (room.roomTypeId == 0) continue;
      options.putIfAbsent(
        room.roomTypeId,
        () => room.roomTypeName.isEmpty
            ? 'Loại phòng ID: ${room.roomTypeId}'
            : room.roomTypeName,
      );
    }

    return options;
  }

  List<Room> applyFilters(List<Room> rooms, List<Booking> bookings) {
    return rooms.where((room) {
      if (selectedRoomTypeId != null && room.roomTypeId != selectedRoomTypeId) {
        return false;
      }

      if (selectedMinGuests != null && room.maxGuests < selectedMinGuests!) {
        return false;
      }

      if (selectedMinBeds != null && room.bedCount < selectedMinBeds!) {
        return false;
      }

      if (selectedStatuses.isNotEmpty &&
          !selectedStatuses.contains(room.status.toLowerCase())) {
        return false;
      }

      if (selectedMinPrice != null && room.pricePerNight < selectedMinPrice!) {
        return false;
      }

      if (selectedMaxPrice != null && room.pricePerNight > selectedMaxPrice!) {
        return false;
      }

      if (selectedDateRange != null &&
          hasBookingInRange(room, bookings, selectedDateRange!)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool hasBookingInRange(
    Room room,
    List<Booking> bookings,
    DateTimeRange range,
  ) {
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);

    return bookings.any((booking) {
      if (!booking.roomIds.contains(room.roomId) ||
          !isActiveBooking(booking.status)) {
        return false;
      }

      final checkIn = DateTime.tryParse(booking.checkIn);
      final checkOut = DateTime.tryParse(booking.checkOut);
      if (checkIn == null || checkOut == null) return false;

      final bookingStart = dateOnly(checkIn);
      final bookingEnd = dateOnly(checkOut);

      return !bookingEnd.isBefore(start) && !bookingStart.isAfter(end);
    });
  }

  bool isActiveBooking(String status) {
    final value = status.toLowerCase();
    return value != 'cancelled' &&
        value != 'canceled' &&
        value != 'completed' &&
        value != 'done';
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String dateRangeLabel(DateTimeRange range) {
    return '${shortDate(range.start)} - ${shortDate(range.end)}';
  }

  double? parseMoneyInput(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Widget datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.navy,
          onPrimary: Colors.white,
          secondary: AppColors.gold,
          onSecondary: AppColors.navy,
          surface: Colors.white,
          onSurface: AppColors.textDark,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: AppColors.navy,
          headerForegroundColor: Colors.white,
          rangePickerBackgroundColor: Colors.white,
          rangePickerHeaderBackgroundColor: AppColors.navy,
          rangePickerHeaderForegroundColor: Colors.white,
          rangePickerHeaderHelpStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          rangePickerHeaderHeadlineStyle: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textGray.withValues(alpha: 0.45);
            }
            return AppColors.textDark;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.navy;
            }
            return null;
          }),
          todayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.navy;
          }),
          todayBorder: const BorderSide(color: AppColors.gold, width: 2),
          rangeSelectionBackgroundColor: AppColors.gold.withValues(alpha: 0.20),
          rangeSelectionOverlayColor: WidgetStateProperty.all(
            AppColors.gold.withValues(alpha: 0.12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.navy),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  void clearFilters() {
    setState(() {
      selectedRoomTypeId = null;
      selectedMinGuests = null;
      selectedMinBeds = null;
      selectedMinPrice = null;
      selectedMaxPrice = null;
      selectedDateRange = null;
      selectedStatuses.clear();
    });
  }

  Future<void> openFilterSheet() async {
    RoomInfoData data;
    try {
      data = await roomFuture;
    } catch (_) {
      data = const RoomInfoData(rooms: [], bookings: []);
    }

    if (!mounted) return;

    final typeOptions = roomTypeOptions(data.rooms);
    final maxGuests = data.rooms.fold<int>(
      0,
      (max, room) => room.maxGuests > max ? room.maxGuests : max,
    );
    final maxBeds = data.rooms.fold<int>(
      0,
      (max, room) => room.bedCount > max ? room.bedCount : max,
    );
    final minPriceController = TextEditingController(
      text: selectedMinPrice?.toStringAsFixed(0) ?? '',
    );
    final maxPriceController = TextEditingController(
      text: selectedMaxPrice?.toStringAsFixed(0) ?? '',
    );

    var tempRoomTypeId = selectedRoomTypeId;
    var tempMinGuests = selectedMinGuests;
    var tempMinBeds = selectedMinBeds;
    var tempDateRange = selectedDateRange;
    final tempStatuses = Set<String>.from(selectedStatuses);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            InputDecoration fieldDecoration(String label) {
              return InputDecoration(
                labelText: label,
                filled: true,
                fillColor: AppColors.background,
                labelStyle: const TextStyle(color: AppColors.textGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.gold, width: 2),
                ),
              );
            }

            List<DropdownMenuItem<int?>> numberItems(int max) {
              return [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tất cả'),
                ),
                ...List.generate(max, (index) {
                  final value = index + 1;
                  return DropdownMenuItem<int?>(
                    value: value,
                    child: Text('Từ $value trở lên'),
                  );
                }),
              ];
            }

            Future<void> pickStayRange() async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: tempDateRange,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: datePickerTheme,
              );

              if (range != null) {
                setModalState(() {
                  tempDateRange = DateTimeRange(
                    start: dateOnly(range.start),
                    end: dateOnly(range.end),
                  );
                });
              }
            }

            void applyFilter() {
              var nextMinPrice = parseMoneyInput(minPriceController.text);
              var nextMaxPrice = parseMoneyInput(maxPriceController.text);

              if (nextMinPrice != null &&
                  nextMaxPrice != null &&
                  nextMinPrice > nextMaxPrice) {
                final temp = nextMinPrice;
                nextMinPrice = nextMaxPrice;
                nextMaxPrice = temp;
              }

              setState(() {
                selectedRoomTypeId = tempRoomTypeId;
                selectedMinGuests = tempMinGuests;
                selectedMinBeds = tempMinBeds;
                selectedMinPrice = nextMinPrice;
                selectedMaxPrice = nextMaxPrice;
                selectedDateRange = tempDateRange;
                selectedStatuses
                  ..clear()
                  ..addAll(tempStatuses);
              });

              Navigator.pop(sheetContext);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12, bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.textGray.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Bộ lọc phòng',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          children: [
                            DropdownButtonFormField<int?>(
                              key: ValueKey('room-type-$tempRoomTypeId'),
                              initialValue: tempRoomTypeId,
                              decoration: fieldDecoration('Loại phòng'),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Tất cả loại phòng'),
                                ),
                                ...typeOptions.entries.map(
                                  (entry) => DropdownMenuItem<int?>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  tempRoomTypeId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    key: ValueKey('guests-$tempMinGuests'),
                                    initialValue: tempMinGuests,
                                    decoration: fieldDecoration('Số người'),
                                    items: numberItems(maxGuests),
                                    onChanged: (value) {
                                      setModalState(() {
                                        tempMinGuests = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    key: ValueKey('beds-$tempMinBeds'),
                                    initialValue: tempMinBeds,
                                    decoration: fieldDecoration('Số giường'),
                                    items: numberItems(maxBeds),
                                    onChanged: (value) {
                                      setModalState(() {
                                        tempMinBeds = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Trạng thái',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: statusOptions.map((entry) {
                                final selected = tempStatuses.contains(
                                  entry.key,
                                );
                                return FilterChip(
                                  label: Text(entry.value),
                                  selected: selected,
                                  selectedColor: AppColors.gold.withValues(
                                    alpha: 0.22,
                                  ),
                                  checkmarkColor: AppColors.navy,
                                  onSelected: (value) {
                                    setModalState(() {
                                      if (value) {
                                        tempStatuses.add(entry.key);
                                      } else {
                                        tempStatuses.remove(entry.key);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: fieldDecoration('Giá từ'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: maxPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: fieldDecoration('Giá đến'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: pickStayRange,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.date_range_rounded,
                                      color: AppColors.gold,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        tempDateRange == null
                                            ? 'Chọn từ ngày đến ngày'
                                            : dateRangeLabel(tempDateRange!),
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (tempDateRange != null)
                                      IconButton(
                                        onPressed: () {
                                          setModalState(() {
                                            tempDateRange = null;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        tempRoomTypeId = null;
                                        tempMinGuests = null;
                                        tempMinBeds = null;
                                        tempDateRange = null;
                                        tempStatuses.clear();
                                        minPriceController.clear();
                                        maxPriceController.clear();
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.navy,
                                      side: const BorderSide(
                                        color: AppColors.navy,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text('Xóa lọc'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: applyFilter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.navy,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      'Áp dụng',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    minPriceController.dispose();
    maxPriceController.dispose();
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
              'Thông tin phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: openFilterSheet,
            style: IconButton.styleFrom(
              backgroundColor: hasActiveFilters
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            icon: const Icon(Icons.filter_alt_rounded, color: AppColors.gold),
          ),
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget roomCard(Room room) {
    final typeName = room.roomTypeName.isEmpty
        ? 'Loại phòng ID: ${room.roomTypeId}'
        : room.roomTypeName;

    return InkWell(
      onTap: () => openRoomDetail(room),
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
                    typeName,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tầng ${room.floor} • ${room.maxGuests} khách • ${room.bedCount} giường',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                  Text(
                    '${money(room.pricePerNight)} VNĐ / đêm',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                  Text(
                    statusLabel(room.status),
                    style: TextStyle(
                      color: statusColor(room.status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget filterSummary(int visibleCount, int totalCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đang lọc: $visibleCount/$totalCount phòng',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: clearFilters, child: const Text('Xóa')),
        ],
      ),
    );
  }

  Widget emptyFilterResult(int totalCount) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (hasActiveFilters) filterSummary(0, totalCount),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            hasActiveFilters
                ? 'Không có phòng phù hợp bộ lọc'
                : 'Không có phòng',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget roomList(List<Room> rooms, int totalCount) {
    if (rooms.isEmpty) {
      return emptyFilterResult(totalCount);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (hasActiveFilters) filterSummary(rooms.length, totalCount),
        ...rooms.map(roomCard),
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
              child: FutureBuilder<RoomInfoData>(
                future: roomFuture,
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

                  final data =
                      snapshot.data ??
                      const RoomInfoData(rooms: [], bookings: []);
                  final filteredRooms = applyFilters(data.rooms, data.bookings);

                  return roomList(filteredRooms, data.rooms.length);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
