import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/const/api_endpoints.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../controller/profile_controller.dart';

class IdCardScreen extends StatefulWidget {
  final UserModel user;
  final ProfileController controller;
  final ValueChanged<UserModel>? onUserUpdated;

  const IdCardScreen({
    super.key,
    required this.user,
    required this.controller,
    this.onUserUpdated,
  });

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  final picker = ImagePicker();
  late UserModel user;
  String? busySide;
  String? errorMessage;
  int imageRevision = 0;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr(AppText.identityCard)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(AppText.identityCardDescription),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _IdCardSide(
            title: context.tr(AppText.identityCardFront),
            hasImage: user.idCardFont.isNotEmpty,
            imageUrl: _imageUrl('front'),
            isBusy: busySide == 'front',
            onPick: () => pickImage('front'),
            onView: () => viewImage('front'),
            onDelete: () => deleteImage('front'),
          ),
          const SizedBox(height: 16),
          _IdCardSide(
            title: context.tr(AppText.identityCardBack),
            hasImage: user.idCardBack.isNotEmpty,
            imageUrl: _imageUrl('back'),
            isBusy: busySide == 'back',
            onPick: () => pickImage('back'),
            onView: () => viewImage('back'),
            onDelete: () => deleteImage('back'),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> pickImage(String side) async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() {
      busySide = side;
      errorMessage = null;
    });
    try {
      final updated = await widget.controller.uploadIdCards(
        currentUser: user,
        frontPath: side == 'front' ? image.path : null,
        backPath: side == 'back' ? image.path : null,
      );
      await persistUser(updated);
    } catch (error) {
      if (mounted) setState(() => errorMessage = _cleanError(error));
    } finally {
      if (mounted) setState(() => busySide = null);
    }
  }

  Future<void> deleteImage(String side) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(AppText.deleteIdentityImage)),
        content: Text(context.tr(AppText.deleteIdentityImageConfirm)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(AppText.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.tr(AppText.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      busySide = side;
      errorMessage = null;
    });
    try {
      final updated = await widget.controller.deleteIdCardImage(
        currentUser: user,
        side: side,
      );
      await persistUser(updated);
    } catch (error) {
      if (mounted) setState(() => errorMessage = _cleanError(error));
    } finally {
      if (mounted) setState(() => busySide = null);
    }
  }

  void viewImage(String side) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                _imageUrl(side),
                headers: const {ngrokSkipBrowserWarningHeader: 'true'},
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 260,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> persistUser(UserModel updated) async {
    await UserModel.updateSavedCurrentUserIfPresent(updated);
    if (!mounted) return;
    setState(() {
      user = updated;
      imageRevision++;
    });
    widget.onUserUpdated?.call(updated);
  }

  String _imageUrl(String side) {
    return '${ApiEndpoints.customerIdCardImage(user.userId, side)}'
        '?v=$imageRevision';
  }
}

class _IdCardSide extends StatelessWidget {
  final String title;
  final bool hasImage;
  final String imageUrl;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _IdCardSide({
    required this.title,
    required this.hasImage,
    required this.imageUrl,
    required this.isBusy,
    required this.onPick,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(hasImage: hasImage),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: AppColors.surface,
                child: isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : hasImage
                    ? Image.network(
                        imageUrl,
                        headers: const {ngrokSkipBrowserWarningHeader: 'true'},
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 42),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onPick,
                  icon: Icon(
                    hasImage
                        ? Icons.edit_outlined
                        : Icons.add_photo_alternate_outlined,
                  ),
                  label: Text(
                    context.tr(
                      hasImage ? AppText.replaceImage : AppText.addImage,
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: isBusy ? null : onView,
                  tooltip: context.tr(AppText.viewImage),
                  icon: const Icon(Icons.visibility_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: isBusy ? null : onDelete,
                  tooltip: context.tr(AppText.delete),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool hasImage;

  const _StatusPill({required this.hasImage});

  @override
  Widget build(BuildContext context) {
    final color = hasImage ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr(hasImage ? AppText.uploaded : AppText.missing),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
