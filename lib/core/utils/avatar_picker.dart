import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';

/// Résultat d'une sélection + recadrage d'avatar.
class PickedAvatar {
  PickedAvatar({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Sélectionne une image (galerie ou caméra) puis la recadre en carré.
///
/// Renvoie `null` si l'utilisateur annule.
class AvatarPicker {
  AvatarPicker._();

  static final ImagePicker _picker = ImagePicker();
  static final ImageCropper _cropper = ImageCropper();

  static Future<PickedAvatar?> pick({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final cropped = await _cropper.cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer',
          toolbarColor: AppColors.brandPrimary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.brandPrimary,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Recadrer',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return null;

    final bytes = await File(cropped.path).readAsBytes();
    return PickedAvatar(bytes: bytes, contentType: 'image/jpeg');
  }
}
