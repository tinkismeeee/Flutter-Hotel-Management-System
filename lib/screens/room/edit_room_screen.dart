import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../utils/app_colors.dart';
import 'room_form_values.dart';

class EditRoomScreen extends StatefulWidget {
  final Room room;

  const EditRoomScreen({super.key, required this.room});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  late TextEditingController roomNumberController;
  late TextEditingController floorController;
  late TextEditingController priceController;
  late TextEditingController maxGuestsController;
  late TextEditingController bedCountController;
  late TextEditingController descriptionController;

  late int selectedRoomTypeId;
  late String status;
  late bool isActive;
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

    roomNumberController = TextEditingController(text: widget.room.roomNumber);
    floorController = TextEditingController(text: widget.room.floor.toString());
    priceController = TextEditingController(
      text: widget.room.pricePerNight.toStringAsFixed(0),
    );
    maxGuestsController = TextEditingController(
      text: widget.room.maxGuests.toString(),
    );
    bedCountController = TextEditingController(
      text: widget.room.bedCount.toString(),
    );
    descriptionController = TextEditingController(
      text: widget.room.description,
    );

    selectedRoomTypeId = widget.room.roomTypeId;
    status = widget.room.status.isEmpty ? 'available' : widget.room.status;
    isActive = widget.room.isActive;
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

  Future<void> updateRoom() async {
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

    final success = await RoomService.updateRoom(
      id: widget.room.roomId,
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

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Cập nhật phòng thành công' : 'Cập nhật phòng thất bại',
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
              'Sửa phòng',
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
                      color: AppColors.gold.withValues(alpha: 0.15),
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
                    activeThumbColor: AppColors.gold,
                    title: const Text('Đang hoạt động'),
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : updateRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Đang cập nhật...' : 'Cập nhật phòng',
                    ),
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
