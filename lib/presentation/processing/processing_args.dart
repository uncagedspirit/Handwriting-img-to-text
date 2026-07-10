import '../../domain/entities/app_enums.dart';

/// Arguments carried into the processing screen: fully prepared (cropped +
/// enhanced) page images ready for OCR.
class ProcessingArgs {
  const ProcessingArgs({
    required this.imagePaths,
    required this.documentTitle,
    required this.batchMode,
  });

  final List<String> imagePaths;
  final String documentTitle;
  final BatchMode batchMode;
}
