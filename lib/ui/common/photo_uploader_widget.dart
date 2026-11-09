import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';

class SelectedPhoto {
  final Uint8List bytes;
  final String name;
  final String extension;

  const SelectedPhoto({
    required this.bytes,
    required this.name,
    required this.extension,
  });
}

class PhotoUploaderWidget extends StatelessWidget {
  final String label;
  final List<SelectedPhoto> photos;
  final ValueChanged<SelectedPhoto> onPhotoAdded;
  final ValueChanged<int> onPhotoRemoved;
  final int maxPhotos;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadStatusText;

  const PhotoUploaderWidget({
    super.key,
    this.label = 'Fotografías de Registro',
    required this.photos,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    this.maxPhotos = 3,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadStatusText,
  });

  String _extractExtension(XFile file) {
    final nameParts = file.name.split('.');
    if (nameParts.length > 1) {
      final ext = nameParts.last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        return ext;
      }
    }
    return 'jpg';
  }

  Future<void> _pickFromSource(BuildContext context, ImageSource source) async {
    if (photos.length >= maxPhotos || isUploading) return;
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        onPhotoAdded(
          SelectedPhoto(
            bytes: bytes,
            name: picked.name,
            extension: _extractExtension(picked),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener la imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSourceSheet(BuildContext context) {
    if (photos.length >= maxPhotos || isUploading) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleccionar fotografía',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Elegir desde Galería'),
                  subtitle: const Text('Archivos locales JPG, PNG o WEBP'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromSource(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Tomar Fotografía'),
                  subtitle: const Text('Capturar directamente con cámara'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromSource(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _previewPhoto(BuildContext context, SelectedPhoto photo, int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Vista previa (${index + 1}/$maxPhotos)'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420, maxWidth: 520),
              child: Image.memory(photo.bytes, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = photos.length < maxPhotos && !isUploading;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.photo_camera_back_outlined,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: photos.length >= maxPhotos
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${photos.length} / $maxPhotos máx.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: photos.length >= maxPhotos
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < photos.length; i++)
                _PhotoTile(
                  photo: photos[i],
                  index: i,
                  disabled: isUploading,
                  onPreview: () => _previewPhoto(context, photos[i], i),
                  onRemove: () => onPhotoRemoved(i),
                ),
              if (canAddMore)
                InkWell(
                  onTap: () => _showSourceSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Añadir foto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (isUploading) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: uploadProgress > 0 ? uploadProgress : null,
                minHeight: 7,
                backgroundColor: const Color(0xFFE5E7EB),
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              uploadStatusText ??
                  'Subiendo fotografías (${(uploadProgress * 100).toInt()}%)...',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final SelectedPhoto photo;
  final int index;
  final bool disabled;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.photo,
    required this.index,
    required this.disabled,
    required this.onPreview,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onPreview,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  photo.bytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!disabled)
            Positioned(
              top: 5,
              right: 5,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

