import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:repair_shop_app/core/l10n/app_strings.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/database/app_database.dart';

/// Thumbnails of saved photos plus photos picked in this session, with an "add" tile (camera or gallery).
class PhotoPickerGrid extends StatelessWidget {
  final List<OrderPhoto> saved;
  final List<String> added;
  final int maxPhotos;
  final ValueChanged<String> onAdd;
  final ValueChanged<OrderPhoto> onRemoveSaved;
  final ValueChanged<String> onRemoveAdded;
  final String? errorText;

  const PhotoPickerGrid({
    super.key,
    required this.saved,
    required this.added,
    required this.onAdd,
    required this.onRemoveSaved,
    required this.onRemoveAdded,
    this.maxPhotos = 6,
    this.errorText,
  });

  static final ImagePicker _picker = ImagePicker();

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.tr(S.camera)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.tr(S.gallery)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    // Downscaled and compressed: enough to show scratches and cracks, small enough to keep many jobs on a phone
    final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 75);
    if (file != null) onAdd(file.path);
  }

  void _preview(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain)),
      ),
    );
  }

  Widget _thumb(BuildContext context, String path, VoidCallback onRemove) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _preview(context, path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              cacheWidth: 252,
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 84,
                color: Colors.grey.withValues(alpha: 0.2),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = saved.length + added.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in saved) _thumb(context, p.filePath, () => onRemoveSaved(p)),
            for (final p in added) _thumb(context, p, () => onRemoveAdded(p)),
            if (count < maxPhotos)
              InkWell(
                onTap: () => _pick(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: errorText != null ? AppTheme.dangerColor : AppTheme.primaryColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryColor),
                      const SizedBox(height: 4),
                      Text(context.tr(S.addPhoto),
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errorText!, style: const TextStyle(color: AppTheme.dangerColor, fontSize: 12)),
          ),
      ],
    );
  }
}
