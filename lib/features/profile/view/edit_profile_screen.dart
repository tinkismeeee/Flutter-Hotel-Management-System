import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../controller/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final ProfileController controller;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;
  late final TextEditingController dateOfBirthController;

  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user.firstName);
    lastNameController = TextEditingController(text: widget.user.lastName);
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phone);
    addressController = TextEditingController(text: widget.user.address);
    dateOfBirthController = TextEditingController(
      text: _dateOnly(widget.user.dateOfBirth),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();
    setState(() => errorMessage = null);
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    try {
      final updatedUser = await widget.controller.updateProfile(
        currentUser: widget.user,
        email: emailController.text,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        phone: phoneController.text,
        address: addressController.text,
        dateOfBirth: dateOfBirthController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(updatedUser);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> pickDate() async {
    final initialDate =
        DateTime.tryParse(dateOfBirthController.text) ??
        DateTime(DateTime.now().year - 18);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate == null) return;

    dateOfBirthController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _EditField(
                      label: 'First name',
                      controller: firstNameController,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EditField(
                      label: 'Last name',
                      controller: lastNameController,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EditField(
                label: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              _EditField(
                label: 'Phone',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _EditField(
                label: 'Address',
                controller: addressController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _EditField(
                label: 'Date of birth',
                controller: dateOfBirthController,
                readOnly: true,
                onTap: pickDate,
                suffixIcon: const Icon(Icons.calendar_month_outlined),
                validator: _validateDate,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email.';
    if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  String? _validateDate(String? value) {
    final date = (value ?? '').trim();
    if (date.isEmpty) return null;
    if (DateTime.tryParse(date) == null) return 'Invalid date.';
    return null;
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final int maxLines;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: InputDecoration(suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}

String _dateOnly(String value) {
  if (value.length < 10) return value;
  return value.substring(0, 10);
}
