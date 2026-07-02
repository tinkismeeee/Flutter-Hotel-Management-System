import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../detail_rooms/view/detail_room_screen.dart';
import '../controller/home_controller.dart';
import '../../../core/models/room_model.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController homeController = HomeController();
  final roomTypes = const [
    'All',
    'Standard',
    'Family',
    'Deluxe',
    'Business',
    'Suite',
  ];

  late Future<HomeData> homeFuture;
  List<RoomModel> rooms = [];
  List<RoomModel> filteredRooms = [];
  List<String> roomImageUrls = [];
  String selectedType = 'All';

  @override
  void initState() {
    super.initState();
    homeFuture = loadHomeData();
  }

  Future<HomeData> loadHomeData() async {
    final data = await homeController.fetchHomeData();
    rooms = data.rooms;
    filteredRooms = homeController.filterRooms(data.rooms, selectedType);
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
      filteredRooms = homeController.filterRooms(rooms, type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
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
                  filteredRooms = homeController.filterRooms(
                    data.rooms,
                    selectedType,
                  );
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
                  SliverToBoxAdapter(child: _Header(user: widget.user)),
                  SliverToBoxAdapter(
                    child: _RoomTypeFilter(
                      roomTypes: roomTypes,
                      selectedType: selectedType,
                      onSelected: filterRooms,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                                        room: room,
                                        imageUrl: imageUrl,
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

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8EAEC),
            child: Text(
              _initials(user),
              style: const TextStyle(
                color: Color(0xFF171725),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? user.username : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF171725),
                    fontSize: 20,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.address.isEmpty ? user.email : user.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF78828A),
                    fontSize: 14,
                    fontFamily: 'Jost',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.history)),
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

class _RoomTypeFilter extends StatelessWidget {
  final List<String> roomTypes;
  final String selectedType;
  final ValueChanged<String> onSelected;

  const _RoomTypeFilter({
    required this.roomTypes,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: roomTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = roomTypes[index];
          final selected = type == selectedType;

          return ChoiceChip(
            label: Text(type),
            selected: selected,
            onSelected: (_) => onSelected(type),
            selectedColor: const Color(0xFF2852AF),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF171725),
              fontFamily: 'Jost',
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
            backgroundColor: const Color(0xFFF6F6F6),
          );
        },
      ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl == null
                    ? const _RoomImagePlaceholder()
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const _RoomImagePlaceholder();
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Room ${room.roomNumber}',
                          style: const TextStyle(
                            color: Color(0xFF171725),
                            fontSize: 18,
                            fontFamily: 'Jost',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _StatusBadge(status: room.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.description,
                    style: const TextStyle(
                      color: Color(0xFF434E58),
                      fontSize: 14,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RoomFacts(room: room),
                ],
              ),
            ),
          ],
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
          text: '${_formatPrice(room.pricePerNight)} VND/night',
        ),
      ],
    );
  }

  String _formatPrice(String value) {
    final number = double.tryParse(value) ?? 0;
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF78828A)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF78828A),
            fontSize: 13,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        color: color.withOpacity(0.12),
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

const _fallbackRoomImageUrls = [
  'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=900&q=80',
];
