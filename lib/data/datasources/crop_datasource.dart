import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/theme/app_colors.dart';

/// Wraps `image_cropper`'s native crop/rotate/straighten UI.
class CropDataSource {
  Future<String?> crop(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Page',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Page'),
      ],
    );
    return cropped?.path;
  }
}
