import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/file_storage.dart';
import '../../core/utils/image_enhancer.dart';
import '../../data/datasources/crop_datasource.dart';
import '../processing/processing_args.dart';

/// Mutable state for a single page while the user reviews/adjusts it.
class PreparePageState {
  PreparePageState({required this.originalPath, required this.workingPath});

  final String originalPath;
  String workingPath;
  double brightness = 0;
  double contrast = 0;
  int rotationDegrees = 0;
}

/// Drives the image preparation screen: crop, rotate, and brightness /
/// contrast adjustment for each captured page before recognition.
class PrepareController extends ChangeNotifier {
  PrepareController({
    required List<String> imagePaths,
    required ImageEnhancer imageEnhancer,
    required CropDataSource cropDataSource,
    required FileStorage fileStorage,
  })  : _enhancer = imageEnhancer,
        _cropper = cropDataSource,
        _storage = fileStorage,
        pages = imagePaths
            .map((p) => PreparePageState(originalPath: p, workingPath: p))
            .toList();

  final ImageEnhancer _enhancer;
  final CropDataSource _cropper;
  final FileStorage _storage;
  final _uuid = const Uuid();

  final List<PreparePageState> pages;
  int currentIndex = 0;
  bool isBusy = false;

  PreparePageState get current => pages[currentIndex];
  bool get isLastPage => currentIndex == pages.length - 1;
  bool get isFirstPage => currentIndex == 0;

  void goTo(int index) {
    currentIndex = index.clamp(0, pages.length - 1);
    notifyListeners();
  }

  void next() {
    if (!isLastPage) goTo(currentIndex + 1);
  }

  void previous() {
    if (!isFirstPage) goTo(currentIndex - 1);
  }

  Future<String> _newTempPath() async {
    final dir = await _storage.tempDir;
    return '${dir.path}/${_uuid.v4()}.jpg';
  }

  Future<void> cropCurrent() async {
    isBusy = true;
    notifyListeners();
    try {
      final result = await _cropper.crop(current.workingPath);
      if (result != null) {
        current.workingPath = result;
      }
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> rotateCurrent() async {
    isBusy = true;
    notifyListeners();
    try {
      final outputPath = await _newTempPath();
      final rotated = await _enhancer.rotate(File(current.workingPath), outputPath, 90);
      current.workingPath = rotated.path;
      current.rotationDegrees = (current.rotationDegrees + 90) % 360;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Updates the live-preview adjustment values for the current page. They
  /// stay exactly where the user set them (no baking, no snap-back); the
  /// pixels are modified later in the processing pipeline where progress is
  /// visible.
  void updateAdjustments({required double brightness, required double contrast}) {
    current.brightness = brightness;
    current.contrast = contrast;
    notifyListeners();
  }

  /// Every page's working image plus its pending manual adjustments, ready
  /// for the processing screen. Heavy pixel work is deliberately not done
  /// here so tapping "Recognize Text" navigates immediately.
  List<PageSpec> finalizeAll() => pages
      .map((p) => PageSpec(
            imagePath: p.workingPath,
            adjustments: ManualAdjustments(brightness: p.brightness, contrast: p.contrast),
          ))
      .toList();
}
