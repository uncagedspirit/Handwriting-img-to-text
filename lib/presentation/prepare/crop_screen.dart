import 'dart:io';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_snackbar.dart';

/// In-app crop editor. Runs entirely inside the Flutter view — the previous
/// native crop activity could crash the whole app with "Reply already
/// submitted" when its result was delivered twice (notably on cancel).
/// Returns the cropped image bytes, or null when the user backs out.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  /// Pushes the crop editor for [imageFile] and returns the cropped bytes,
  /// or null if the user cancelled.
  static Future<Uint8List?> open(BuildContext context, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (!context.mounted) return null;
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropScreen(imageBytes: bytes)),
    );
  }

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        setState(() => _isCropping = false);
        AppSnackBar.error(context, "This image couldn't be cropped. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Page')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Crop(
                image: widget.imageBytes,
                controller: _controller,
                onCropped: _onCropped,
                baseColor: Theme.of(context).scaffoldBackgroundColor,
                maskColor: Colors.black38,
                radius: 8,
                initialRectBuilder: InitialRectBuilder.withSizeAndRatio(size: 0.9),
                progressIndicator: const CircularProgressIndicator(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCropping ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isCropping
                          ? null
                          : () {
                              setState(() => _isCropping = true);
                              _controller.crop();
                            },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isCropping
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Crop'),
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
