import 'package:flutter/material.dart';
import '../../models/room_type.dart';
import '../../services/room_type_service.dart';
import '../../utils/app_colors.dart';

class EditRoomTypeScreen extends StatefulWidget {
  final RoomType roomType;

  const EditRoomTypeScreen({
    super.key,
    required this.roomType,
  });

  @override
  State<EditRoomTypeScreen> createState() => _EditRoomTypeScreenState();
}

class _EditRoomTypeScreenState extends State<EditRoomTypeScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.roomType.name,
    );
    descriptionController = TextEditingController(
      text: widget.roomType.description,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> updateRoomType() async {
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await RoomTypeService.updateRoomType(
      id: widget.roomType.roomTypeId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Cập nhật loại phòng thành công'
              : 'Cập nhật loại phòng thất bại',
        ),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  Widget inputField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: AppColors.textGray,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.gold,
              width: 2,
            ),
          ),
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
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.gold,
            ),
          ),
          const Expanded(
            child: Text(
              'Sửa loại phòng',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID loại phòng: ${widget.roomType.roomTypeId}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  inputField(
                    'Tên loại phòng',
                    nameController,
                  ),
                  inputField(
                    'Mô tả',
                    descriptionController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : updateRoomType,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isLoading
                          ? 'Đang cập nhật...'
                          : 'Cập nhật loại phòng',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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