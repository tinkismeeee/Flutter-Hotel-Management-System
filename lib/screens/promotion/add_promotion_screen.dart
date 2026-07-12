import 'package:flutter/material.dart';
import '../../services/promotion_service.dart';
import '../../utils/app_colors.dart';

class AddPromotionScreen extends StatefulWidget {
  const AddPromotionScreen({super.key});

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  final promotionCodeController = TextEditingController();
  final nameController = TextEditingController();
  final discountController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final descriptionController = TextEditingController();

  String scope = 'invoice';
  bool isActive = true;
  bool isLoading = false;

  @override
  void dispose() {
    promotionCodeController.dispose();
    nameController.dispose();
    discountController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2025, 12, 1),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      controller.text =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> addPromotion() async {
    if (promotionCodeController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        discountController.text.trim().isEmpty ||
        startDateController.text.trim().isEmpty ||
        endDateController.text.trim().isEmpty ||
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

    final success = await PromotionService.addPromotion(
      promotionCode: promotionCodeController.text.trim(),
      name: nameController.text.trim(),
      discountValue: double.parse(discountController.text.trim()),
      startDate: startDateController.text.trim(),
      endDate: endDateController.text.trim(),
      scope: scope,
      description: descriptionController.text.trim(),
      isActive: isActive,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Thêm khuyến mãi thành công'
              : 'Thêm khuyến mãi thất bại',
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
        VoidCallback? onTap,
        int maxLines = 1,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
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
            borderSide: const BorderSide(
              color: AppColors.gold,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget scopeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: scope,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'invoice', child: Text('invoice')),
            DropdownMenuItem(value: 'room', child: Text('room')),
            DropdownMenuItem(value: 'service', child: Text('service')),
          ],
          onChanged: (value) {
            setState(() {
              scope = value ?? 'invoice';
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
              'Thêm khuyến mãi',
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
                  inputField('Mã khuyến mãi', promotionCodeController),
                  inputField('Tên khuyến mãi', nameController),
                  inputField(
                    'Giá trị giảm (%)',
                    discountController,
                    type: TextInputType.number,
                  ),
                  inputField(
                    'Ngày bắt đầu',
                    startDateController,
                    readOnly: true,
                    onTap: () => pickDate(startDateController),
                  ),
                  inputField(
                    'Ngày kết thúc',
                    endDateController,
                    readOnly: true,
                    onTap: () => pickDate(endDateController),
                  ),

                  scopeDropdown(),

                  inputField(
                    'Mô tả',
                    descriptionController,
                    maxLines: 4,
                  ),

                  SwitchListTile(
                    value: isActive,
                    activeColor: AppColors.gold,
                    title: const Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : addPromotion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isLoading
                          ? 'Đang thêm...'
                          : 'Thêm khuyến mãi',
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