import 'package:flutter/material.dart';

import '../../models/promotion.dart';
import '../../services/promotion_service.dart';
import '../../utils/app_colors.dart';

class EditPromotionScreen extends StatefulWidget {
  final Promotion promotion;

  const EditPromotionScreen({
    super.key,
    required this.promotion,
  });

  @override
  State<EditPromotionScreen> createState() => _EditPromotionScreenState();
}

class _EditPromotionScreenState extends State<EditPromotionScreen> {
  late TextEditingController nameController;
  late TextEditingController discountController;
  late TextEditingController startDateController;
  late TextEditingController endDateController;
  late TextEditingController descriptionController;

  late String scope;
  late bool isActive;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.promotion.name);
    discountController = TextEditingController(
      text: widget.promotion.discountValue.toStringAsFixed(0),
    );
    startDateController = TextEditingController(
      text: shortDate(widget.promotion.startDate),
    );
    endDateController = TextEditingController(
      text: shortDate(widget.promotion.endDate),
    );
    descriptionController = TextEditingController(
      text: widget.promotion.description,
    );
    scope = widget.promotion.scope.isEmpty ? 'invoice' : widget.promotion.scope;
    isActive = widget.promotion.isActive;
  }

  @override
  void dispose() {
    nameController.dispose();
    discountController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String shortDate(String value) {
    if (value.isEmpty) return '';
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  Future<void> pickDate(TextEditingController controller) async {
    final initialDate =
        DateTime.tryParse(controller.text.trim()) ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      controller.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> updatePromotion() async {
    final discount = double.tryParse(discountController.text.trim());

    if (nameController.text.trim().isEmpty ||
        discount == null ||
        startDateController.text.trim().isEmpty ||
        endDateController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin hợp lệ')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await PromotionService.updatePromotion(
      id: widget.promotion.promotionId,
      name: nameController.text.trim(),
      discountValue: discount,
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
              ? 'Cập nhật mã giảm giá thành công'
              : 'Cập nhật mã giảm giá thất bại',
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
            borderSide: const BorderSide(color: AppColors.gold, width: 2),
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
            DropdownMenuItem(value: 'invoice', child: Text('Hóa đơn')),
            DropdownMenuItem(value: 'room', child: Text('Phòng')),
            DropdownMenuItem(value: 'service', child: Text('Dịch vụ')),
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
              'Sửa mã giảm giá',
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
                      'Mã giảm giá: ${widget.promotion.promotionCode}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  inputField('Tên mã giảm giá', nameController),
                  inputField(
                    'Giá trị giảm (%)',
                    discountController,
                    type: const TextInputType.numberWithOptions(decimal: true),
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
                    activeThumbColor: AppColors.gold,
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
                    onPressed: isLoading ? null : updatePromotion,
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
                          ? 'Đang cập nhật...'
                          : 'Cập nhật mã giảm giá',
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
