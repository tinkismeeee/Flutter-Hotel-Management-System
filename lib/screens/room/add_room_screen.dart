import 'package:flutter/material.dart';
import '../../services/room_service.dart';
import '../../utils/app_colors.dart';
import 'room_form_values.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final roomNumberController = TextEditingController();
  final floorController = TextEditingController();
  final priceController = TextEditingController();
  final maxGuestsController = TextEditingController();
  final bedCountController = TextEditingController();
  final descriptionController = TextEditingController();

  int selectedRoomTypeId = 1;

  String status = 'available';
  bool isActive = true;
  bool isLoading = false;

  final List<Map<String, dynamic>> roomTypes = [
    {
      'id': 1,
      'name': 'Standard',
      'price': 500000.0,
      'description': 'Basic room with one bed',
    },
    {
      'id': 2,
      'name': 'Deluxe',
      'price': 1200000.0,
      'description': 'Spacious room with city view',
    },
    {
      'id': 3,
      'name': 'Suite',
      'price': 2500000.0,
      'description': 'Luxury room with living area and kitchen',
    },
    {
      'id': 4,
      'name': 'Family',
      'price': 580000.0,
      'description': 'Large room for family stay',
    },
    {
      'id': 5,
      'name': 'Business',
      'price': 1500000.0,
      'description': 'Room with working desk and Wi-Fi',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  void updateRoomTypeInfo(int roomTypeId) {
    setState(() {
      selectedRoomTypeId = roomTypeId;
    });
  }

  @override
  void dispose() {
    roomNumberController.dispose();
    floorController.dispose();
    priceController.dispose();
    maxGuestsController.dispose();
    bedCountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> addRoom() async {
    if (roomNumberController.text.trim().isEmpty ||
        floorController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        maxGuestsController.text.trim().isEmpty ||
        bedCountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final values = RoomFormValues.tryParse(
      floor: floorController.text.trim(),
      pricePerNight: priceController.text.trim(),
      maxGuests: maxGuestsController.text.trim(),
      bedCount: bedCountController.text.trim(),
    );
    if (values == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid room values')));
      return;
    }

    setState(() => isLoading = true);
    final success = await RoomService.addRoom(
      roomNumber: roomNumberController.text.trim(),
      roomTypeId: selectedRoomTypeId,
      floor: values.floor,
      pricePerNight: values.pricePerNight,
      maxGuests: values.maxGuests,
      bedCount: values.bedCount,
      description: descriptionController.text.trim(),
      status: status,
      isActive: isActive,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Thêm phòng thành công' : 'Thêm phòng thất bại',
        ),
      ),
    );

    if (success) Navigator.pop(context);
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
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
      ),
    );
  }

  Widget roomTypeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedRoomTypeId,
          isExpanded: true,
          items: roomTypes.map((type) {
            return DropdownMenuItem<int>(
              value: type['id'],
              child: Text(
                '${type['name']} - ${type['price'].toStringAsFixed(0)} VNĐ',
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              updateRoomTypeInfo(value);
            }
          },
        ),
      ),
    );
  }

  Widget statusDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'available', child: Text('available')),
            DropdownMenuItem(value: 'booked', child: Text('booked')),
            DropdownMenuItem(value: 'maintenance', child: Text('maintenance')),
          ],
          onChanged: (value) {
            setState(() {
              status = value ?? 'available';
            });
          },
        ),
      ),
    );
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
              'Thêm phòng',
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

  @override
  Widget build(BuildContext context) {
    final selectedRoomType = roomTypes.firstWhere(
      (item) => item['id'] == selectedRoomTypeId,
    );

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
                  inputField('Số phòng', roomNumberController),

                  roomTypeDropdown(),

                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Loại phòng: ${selectedRoomType['name']}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  inputField(
                    'Tầng',
                    floorController,
                    type: TextInputType.number,
                  ),
                  inputField(
                    'Giá mỗi đêm',
                    priceController,
                    type: TextInputType.number,
                  ),
                  inputField(
                    'Số khách tối đa',
                    maxGuestsController,
                    type: TextInputType.number,
                  ),
                  inputField(
                    'Số giường',
                    bedCountController,
                    type: TextInputType.number,
                  ),
                  inputField('Mô tả', descriptionController),

                  statusDropdown(),

                  SwitchListTile(
                    value: isActive,
                    activeColor: AppColors.gold,
                    title: const Text('Đang hoạt động'),
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : addRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(isLoading ? 'Đang thêm...' : 'Thêm phòng'),
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
