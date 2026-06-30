import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../utils/app_colors.dart';

class EditRoomScreen extends StatefulWidget {
  final Room room;

  const EditRoomScreen({
    super.key,
    required this.room,
  });

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  late TextEditingController roomNumberController;
  late TextEditingController roomTypeIdController;
  late TextEditingController floorController;
  late TextEditingController priceController;
  late TextEditingController maxGuestsController;
  late TextEditingController bedCountController;
  late TextEditingController descriptionController;

  late String status;
  late bool isActive;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    roomNumberController = TextEditingController(text: widget.room.roomNumber);
    roomTypeIdController = TextEditingController(text: widget.room.roomTypeId.toString());
    floorController = TextEditingController(text: widget.room.floor.toString());
    priceController = TextEditingController(text: widget.room.pricePerNight.toStringAsFixed(0));
    maxGuestsController = TextEditingController(text: widget.room.maxGuests.toString());
    bedCountController = TextEditingController(text: widget.room.bedCount.toString());
    descriptionController = TextEditingController(text: widget.room.description);

    status = widget.room.status.isEmpty ? 'available' : widget.room.status;
    isActive = widget.room.isActive;
  }

  @override
  void dispose() {
    roomNumberController.dispose();
    roomTypeIdController.dispose();
    floorController.dispose();
    priceController.dispose();
    maxGuestsController.dispose();
    bedCountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> updateRoom() async {
    setState(() => isLoading = true);

    final success = await RoomService.updateRoom(
      id: widget.room.roomId,
      roomNumber: roomNumberController.text.trim(),
      roomTypeId: int.parse(roomTypeIdController.text.trim()),
      floor: int.parse(floorController.text.trim()),
      pricePerNight: double.parse(priceController.text.trim()),
      maxGuests: int.parse(maxGuestsController.text.trim()),
      bedCount: int.parse(bedCountController.text.trim()),
      description: descriptionController.text.trim(),
      status: status,
      isActive: isActive,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Cập nhật phòng thành công' : 'Cập nhật phòng thất bại')),
    );

    if (success) Navigator.pop(context);
  }

  Widget inputField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: type,
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
                  inputField('ID loại phòng', roomTypeIdController, type: TextInputType.number),
                  inputField('Tầng', floorController, type: TextInputType.number),
                  inputField('Giá mỗi đêm', priceController, type: TextInputType.number),
                  inputField('Số khách tối đa', maxGuestsController, type: TextInputType.number),
                  inputField('Số giường', bedCountController, type: TextInputType.number),
                  inputField('Mô tả', descriptionController),
                  statusDropdown(),

                  SwitchListTile(
                    value: isActive,
                    activeColor: AppColors.gold,
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
                    child: Text(isLoading ? 'Đang cập nhật...' : 'Cập nhật phòng'),
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