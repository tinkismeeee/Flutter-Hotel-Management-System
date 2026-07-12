import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/user_model.dart';
import '../controller/home_controller.dart';
import '../../../core/models/room_model.dart';
import '../../bookings/view/my_bookings_screen.dart';
import '../../detail_rooms/view/detail_room_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final HomeController homeController = HomeController();
  final TextEditingController searchController = TextEditingController();
  final roomTypes = const [
    'All',
    'Standard',
    'Family',
    'Deluxe',
    'Business',
    'Suite',
  ];
  final roomStatuses = const [
    'All Status',
    'Available',
    'Booked',
    'Maintenance',
  ];

  late Future<HomeData> homeFuture;
  List<RoomModel> rooms = [];
  List<RoomModel> filteredRooms = [];
  List<String> roomImageUrls = [];
  String selectedType = 'All';
  String selectedStatus = 'All Status';
  String searchQuery = '';
  double minPrice = 0;
  double maxPrice = 0;
  RangeValues selectedPriceRange = const RangeValues(0, 0);

  @override
  void initState() {
    super.initState();
    homeFuture = loadHomeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<HomeData> loadHomeData() async {
    final data = await homeController.fetchHomeData();
    rooms = data.rooms;
    updatePriceBounds(data.rooms);
    filteredRooms = applyFilters(data.rooms);
    roomImageUrls =
        data.roomImages
            .map((image) => image.urls.regular)
            .where((url) => url.isNotEmpty)
            .toSet()
            .toList()
          ..shuffle();
    return data;
  }

  void filterRooms(String type) {
    setState(() {
      selectedType = type;
      filteredRooms = applyFilters(rooms);
    });
  }

  void filterRoomsByStatus(String status) {
    setState(() {
      selectedStatus = status;
      filteredRooms = applyFilters(rooms);
    });
  }

  void filterRoomsByPrice(RangeValues range) {
    setState(() {
      selectedPriceRange = range;
      filteredRooms = applyFilters(rooms);
    });
  }

  void resetFilters() {
    setState(() {
      selectedType = 'All';
      selectedStatus = 'All Status';
      selectedPriceRange = RangeValues(minPrice, maxPrice);
      filteredRooms = applyFilters(rooms);
    });
  }

  void searchRooms(String query) {
    setState(() {
      searchQuery = query.trim().toLowerCase();
      filteredRooms = applyFilters(rooms);
    });
  }

  List<RoomModel> applyFilters(List<RoomModel> source) {
    final typedRooms = homeController.filterRooms(source, selectedType);
    final statusRooms = selectedStatus == 'All Status'
        ? typedRooms
        : typedRooms
              .where((room) => room.status == selectedStatus.toLowerCase())
              .toList();
    final priceRooms = maxPrice <= minPrice
        ? statusRooms
        : statusRooms.where((room) {
            final price = _parseRoomPrice(room.pricePerNight);
            return price >= selectedPriceRange.start &&
                price <= selectedPriceRange.end;
          }).toList();

    if (searchQuery.isEmpty) return priceRooms;

    return priceRooms.where((room) {
      final text = [
        room.roomNumber,
        room.roomTypeName,
        room.description,
        room.status,
        room.floor.toString(),
      ].join(' ').toLowerCase();

      return text.contains(searchQuery);
    }).toList();
  }

  void updatePriceBounds(List<RoomModel> source) {
    if (source.isEmpty) return;

    final prices = source.map((room) => _parseRoomPrice(room.pricePerNight));
    minPrice = prices.reduce((a, b) => a < b ? a : b);
    maxPrice = prices.reduce((a, b) => a > b ? a : b);
    selectedPriceRange = RangeValues(minPrice, maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFFEFEFE),
      drawer: _FilterDrawer(
        roomTypes: roomTypes,
        roomStatuses: roomStatuses,
        selectedType: selectedType,
        selectedStatus: selectedStatus,
        minPrice: minPrice,
        maxPrice: maxPrice,
        selectedPriceRange: selectedPriceRange,
        onTypeSelected: filterRooms,
        onStatusSelected: filterRoomsByStatus,
        onPriceChanged: filterRoomsByPrice,
        onReset: resetFilters,
      ),
      body: SafeArea(
        child: FutureBuilder<HomeData>(
          future: homeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _HomeSkeleton();
            }

            if (snapshot.hasError) {
              return _HomeError(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() {
                    homeFuture = loadHomeData();
                  });
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final data = await loadHomeData();
                setState(() {
                  rooms = data.rooms;
                  filteredRooms = applyFilters(data.rooms);
                  roomImageUrls =
                      data.roomImages
                          .map((image) => image.urls.regular)
                          .where((url) => url.isNotEmpty)
                          .toSet()
                          .toList()
                        ..shuffle();
                });
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      user: widget.user,
                      searchController: searchController,
                      onSearchChanged: searchRooms,
                      onFilterPressed: () {
                        scaffoldKey.currentState?.openDrawer();
                      },
                      onBookingsPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MyBookingsScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _HomeSummary(
                      totalRooms: rooms.length,
                      visibleRooms: filteredRooms.length,
                      availableRooms: rooms
                          .where((room) => room.status == 'available')
                          .length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    sliver: filteredRooms.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(child: Text('No rooms found')),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index.isOdd) {
                                return const SizedBox(height: 14);
                              }

                              final roomIndex = index ~/ 2;
                              final room = filteredRooms[roomIndex];
                              final images = roomImageUrls.isEmpty
                                  ? _fallbackRoomImageUrls
                                  : roomImageUrls;
                              final imageUrl = roomIndex < images.length
                                  ? images[roomIndex]
                                  : null;
                              return _RoomCard(
                                room: room,
                                imageUrl: imageUrl,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DetailRoomScreen(
                                        roomId: room.roomId,
                                        imageUrl: imageUrl,
                                        user: widget.user,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: filteredRooms.length * 2 - 1),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserModel user;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onBookingsPressed;

  const _Header({
    required this.user,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.onBookingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEEF4FF),
                child: Text(
                  _initials(user),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      fullName.isEmpty ? user.username : fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onFilterPressed,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.tune),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onBookingsPressed,
                tooltip: 'My bookings',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Find your perfect room',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search room number, type, status',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                    ),
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(UserModel user) {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$first$last';
    if (initials.isNotEmpty) return initials.toUpperCase();
    return user.username.isEmpty ? '?' : user.username[0].toUpperCase();
  }
}

class _HomeSummary extends StatelessWidget {
  final int totalRooms;
  final int visibleRooms;
  final int availableRooms;

  const _HomeSummary({
    required this.totalRooms,
    required this.visibleRooms,
    required this.availableRooms,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Showing',
              value: visibleRooms.toString(),
              icon: Icons.hotel_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              label: 'Available',
              value: availableRooms.toString(),
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              label: 'Total',
              value: totalRooms.toString(),
              icon: Icons.meeting_room_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDrawer extends StatelessWidget {
  final List<String> roomTypes;
  final List<String> roomStatuses;
  final String selectedType;
  final String selectedStatus;
  final double minPrice;
  final double maxPrice;
  final RangeValues selectedPriceRange;
  final ValueChanged<String> onTypeSelected;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<RangeValues> onPriceChanged;
  final VoidCallback onReset;

  const _FilterDrawer({
    required this.roomTypes,
    required this.roomStatuses,
    required this.selectedType,
    required this.selectedStatus,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedPriceRange,
    required this.onTypeSelected,
    required this.onStatusSelected,
    required this.onPriceChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DrawerFilterSection(
                title: 'Room type',
                labels: roomTypes,
                selectedLabel: selectedType,
                onSelected: onTypeSelected,
              ),
              const SizedBox(height: 24),
              _DrawerFilterSection(
                title: 'Room status',
                labels: roomStatuses,
                selectedLabel: selectedStatus,
                onSelected: onStatusSelected,
              ),
              const SizedBox(height: 24),
              _DrawerPriceSection(
                minPrice: minPrice,
                maxPrice: maxPrice,
                selectedPriceRange: selectedPriceRange,
                onChanged: onPriceChanged,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFilterSection extends StatelessWidget {
  final String title;
  final List<String> labels;
  final String selectedLabel;
  final ValueChanged<String> onSelected;

  const _DrawerFilterSection({
    required this.title,
    required this.labels,
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.map((label) {
            final selected = label == selectedLabel;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onSelected(label),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: selected ? AppColors.background : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DrawerPriceSection extends StatelessWidget {
  final double minPrice;
  final double maxPrice;
  final RangeValues selectedPriceRange;
  final ValueChanged<RangeValues> onChanged;

  const _DrawerPriceSection({
    required this.minPrice,
    required this.maxPrice,
    required this.selectedPriceRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canSlide = maxPrice > minPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price range',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canSlide
                    ? '${_formatRoomPrice(selectedPriceRange.start.toString())} - ${_formatRoomPrice(selectedPriceRange.end.toString())} VND'
                    : 'No price range',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: selectedPriceRange,
                min: minPrice,
                max: canSlide ? maxPrice : minPrice + 1,
                divisions: canSlide ? 20 : null,
                labels: RangeLabels(
                  _formatRoomPrice(selectedPriceRange.start.toString()),
                  _formatRoomPrice(selectedPriceRange.end.toString()),
                ),
                onChanged: canSlide ? onChanged : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final String? imageUrl;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoomImageFrame(
                imageUrl: imageUrl,
                status: room.status,
                price: _formatRoomPrice(room.pricePerNight),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Room ${room.roomNumber}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RoomFacts(room: room),
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

class _RoomImageFrame extends StatelessWidget {
  final String? imageUrl;
  final String status;
  final String price;

  const _RoomImageFrame({
    required this.imageUrl,
    required this.status,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.background, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
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
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _StatusBadge(status: status),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$price VND',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      '/ night',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  const _RoomFacts({required this.room});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _Fact(icon: Icons.layers_outlined, text: 'Floor ${room.floor}'),
        _Fact(icon: Icons.category_outlined, text: room.roomTypeName),
        _Fact(icon: Icons.people_outline, text: '${room.maxGuests} guests'),
        _Fact(icon: Icons.bed_outlined, text: '${room.bedCount} beds'),
        _Fact(
          icon: Icons.payments_outlined,
          text: '${_formatRoomPrice(room.pricePerNight)} VND/night',
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeError({required this.message, required this.onRetry});

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

class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();

  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton> {
  bool faded = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          faded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: faded ? 0.45 : 1,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) {
          setState(() {
            faded = !faded;
          });
        }
      },
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: Row(
                children: [
                  const _SkeletonBox(width: 56, height: 56, radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonBox(width: 150, height: 20),
                        SizedBox(height: 8),
                        _SkeletonBox(width: 220, height: 14),
                      ],
                    ),
                  ),
                  const _SkeletonBox(width: 40, height: 40, radius: 20),
                  const SizedBox(width: 8),
                  const _SkeletonBox(width: 40, height: 40, radius: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return const _SkeletonBox(width: 86, height: 36, radius: 18);
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: 5,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) return const SizedBox(height: 14);
                return const _RoomCardSkeleton();
              }, childCount: 5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCardSkeleton extends StatelessWidget {
  const _RoomCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SkeletonBox(width: double.infinity, height: 160, radius: 10),
            SizedBox(height: 14),
            _SkeletonBox(width: 140, height: 18),
            SizedBox(height: 10),
            _SkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: 8),
            _SkeletonBox(width: 220, height: 14),
            SizedBox(height: 14),
            _SkeletonBox(width: 260, height: 16),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAEC),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

String _formatRoomPrice(String value) {
  final number = _parseRoomPrice(value);
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

double _parseRoomPrice(String value) {
  return double.tryParse(value) ?? 0;
}

const _fallbackRoomImageUrls = [
  'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=900&q=80',
];
