import '../../core/utils/image_enhancer.dart';
import '../../domain/entities/app_enums.dart';

/// One prepared page headed into recognition: its working image plus any
/// manual brightness/contrast the user dialed in (baked during processing,
/// where progress is visible, rather than blocking the prepare screen).
class PageSpec {
  const PageSpec({required this.imagePath, required this.adjustments});

  final String imagePath;
  final ManualAdjustments adjustments;
}

/// Arguments carried into the processing screen.
class ProcessingArgs {
  const ProcessingArgs({
    required this.pages,
    required this.documentTitle,
    required this.batchMode,
  });

  final List<PageSpec> pages;
  final String documentTitle;
  final BatchMode batchMode;
}
