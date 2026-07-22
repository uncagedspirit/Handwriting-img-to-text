import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/file_storage.dart';
import '../../core/utils/image_enhancer.dart';
import '../../data/datasources/text_recognition_datasource.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/scan_document.dart';
import '../../domain/entities/scan_page.dart';
import 'processing_args.dart';

enum ProcessingStage { preparing, recognizing, saving, done, failed }

/// Runs OCR across every prepared page and assembles the resulting
/// [ScanDocument](s), respecting the merge/separate batch choice and the
/// keep-original-image / auto-save-history settings.
class ProcessingController extends ChangeNotifier {
  ProcessingController({
    required this.pageSpecs,
    required this.documentTitle,
    required this.batchMode,
    required TextRecognitionDataSource recognizer,
    required HistoryRepository historyRepository,
    required SettingsRepository settingsRepository,
    required FileStorage fileStorage,
    required ImageEnhancer imageEnhancer,
    required AnalyticsService analytics,
  })  : _recognizer = recognizer,
        _history = historyRepository,
        _settings = settingsRepository,
        _storage = fileStorage,
        _enhancer = imageEnhancer,
        _analytics = analytics;

  final List<PageSpec> pageSpecs;
  final String documentTitle;
  final BatchMode batchMode;

  final TextRecognitionDataSource _recognizer;
  final HistoryRepository _history;
  final SettingsRepository _settings;
  final FileStorage _storage;
  final ImageEnhancer _enhancer;
  final AnalyticsService _analytics;
  final _uuid = const Uuid();

  ProcessingStage stage = ProcessingStage.preparing;

  /// Overall completion, 0..1, advanced through sub-steps within each page
  /// so the bar moves smoothly instead of jumping page-to-page. Monotonic —
  /// it never slides backward.
  double progress = 0;

  /// Plain-language description of the work happening right now.
  String phaseLabel = 'Getting ready';

  /// 1-based index of the page currently being worked on.
  int currentPageNumber = 0;

  int get totalPages => pageSpecs.length;

  String? errorMessage;
  String? errorSuggestion;
  bool _isCancelled = false;
  bool _isDisposed = false;

  /// Reports progress at a fractional point [withinPage] (0..1) through the
  /// page at [pageIndex], mapped onto the overall bar.
  void _report(int pageIndex, double withinPage, String label) {
    if (totalPages == 0) return;
    final overall = (pageIndex + withinPage.clamp(0.0, 1.0)) / totalPages;
    if (overall > progress) progress = overall;
    phaseLabel = label;
    currentPageNumber = pageIndex + 1;
    notifyListeners();
  }

  /// Stops the pipeline at the next checkpoint. Work already handed to an
  /// isolate finishes, but nothing further is started and no document is
  /// saved, so the user is never trapped watching a long batch.
  void cancel() {
    _isCancelled = true;
  }

  /// Cancelling pops this screen and disposes the controller while the
  /// pipeline is still unwinding, so every progress update must be a no-op
  /// once that has happened.
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isCancelled = true;
    super.dispose();
  }

  /// The single merged document, populated when [batchMode] is merge.
  ScanDocument? resultDocument;

  /// The set of documents created, populated when [batchMode] is separate.
  List<ScanDocument> resultDocuments = const [];

  /// A first-pass result at least this good means the photo was already
  /// clear. Spending seconds building enhanced variants to maybe gain a
  /// character or two is not worth making the user wait.
  static const _goodEnoughConfidence = 0.70;
  static const _goodEnoughChars = 25;

  /// Threshold used when the device reports no confidence at all: a page
  /// that yielded this much text clearly read fine.
  static const _goodEnoughCharsNoConfidence = 80;

  Future<void> run() async {
    progress = 0;
    stage = ProcessingStage.recognizing;
    _report(0, 0, totalPages > 1 ? 'Reading page 1' : 'Reading your handwriting');

    final autoEnhance = _settings.imageEnhancementEnabled;
    final language = _settings.recognitionLanguage;
    final keepOriginal = _settings.keepOriginalImage;
    final now = DateTime.now();
    final pages = <ScanPage>[];

    try {
      for (var i = 0; i < pageSpecs.length; i++) {
        if (_isCancelled) return;
        final spec = pageSpecs[i];
        final pageLabel = totalPages > 1 ? ' page ${i + 1}' : ' your handwriting';

        final dir = await _storage.tempDir;
        var basePath = spec.imagePath;

        // Bake the user's prepare-screen brightness/contrast first so the
        // kept page matches the live preview they saw.
        if (!spec.adjustments.isNeutral) {
          _report(i, 0.05, 'Applying your adjustments');
          final adjusted = await _enhancer.applyManualAdjustments(
            File(basePath),
            '${dir.path}/${_uuid.v4()}.jpg',
            spec.adjustments,
          );
          await _storage.deleteIfExists(basePath);
          basePath = adjusted.path;
        }

        var best = RecognitionOutcome.empty;
        var failed = false;
        final scratchPaths = <String>[];

        try {
          // Fast path: recognize the photo as-is. ML Kit runs natively and
          // finishes in about a second, so a clear page never pays for any
          // pure-Dart image processing at all.
          _report(i, 0.15, 'Reading$pageLabel');
          stage = ProcessingStage.recognizing;
          best = await _recognizer.tryRecognize(basePath, language);
          _report(i, 0.4, 'Reading$pageLabel');

          if (autoEnhance && !_isGoodEnough(best) && !_isCancelled) {
            stage = ProcessingStage.preparing;
            _report(i, 0.5, 'Sharpening$pageLabel');

            final variants = await _enhancer.buildOcrVariants(
              File(basePath),
              '${dir.path}/${_uuid.v4()}.jpg',
              '${dir.path}/${_uuid.v4()}.jpg',
            );
            scratchPaths.addAll(variants.paths);

            stage = ProcessingStage.recognizing;
            _report(i, 0.65, 'Reading$pageLabel again');

            var read = 0;
            for (final path in variants.paths) {
              if (_isCancelled) return;
              final outcome = await _recognizer.tryRecognize(path, language);
              if (outcome.score > best.score) best = outcome;
              read++;
              _report(i, 0.65 + 0.2 * (read / variants.paths.length), 'Reading$pageLabel again');
              if (_isGoodEnough(outcome)) break;
            }
          }

          // Still nothing readable: the page may simply be sideways or
          // upside down (an import with no orientation metadata), so retry
          // at each remaining rotation.
          if (best.text.trim().isEmpty && !_isCancelled) {
            _report(i, 0.85, 'Checking page orientation');
            for (final degrees in const [90, 180, 270]) {
              if (_isCancelled) return;
              final rotated = await _enhancer.rotate(
                File(basePath),
                '${dir.path}/${_uuid.v4()}.jpg',
                degrees,
              );
              scratchPaths.add(rotated.path);
              final outcome = await _recognizer.tryRecognize(rotated.path, language);
              if (outcome.score > best.score) {
                best = outcome;
                // A rotated page should be kept the way it reads.
                await _storage.deleteIfExists(basePath);
                basePath = rotated.path;
                scratchPaths.remove(rotated.path);
                break;
              }
            }
          }

          failed = best.text.trim().isEmpty;
        } on AppException {
          failed = true;
        }

        _report(i, 0.95, 'Finishing$pageLabel');

        // Always keep the real photo, never a derived black-and-white or
        // levels-stretched variant — those exist only to be read.
        final persistedPath = await _persistPage(basePath, keepOriginal);
        for (final path in {...scratchPaths, basePath}) {
          await _storage.deleteIfExists(path);
        }

        pages.add(ScanPage(
          id: _uuid.v4(),
          imagePath: persistedPath,
          recognizedText: best.text,
          hasRecognitionFailed: failed,
        ));

        _report(i, 1.0, 'Finishing$pageLabel');
      }

      if (_isCancelled) return;

      stage = ProcessingStage.saving;
      phaseLabel = 'Saving your document';
      progress = 1;
      notifyListeners();

      if (batchMode == BatchMode.merge) {
        final doc = ScanDocument(
          id: _uuid.v4(),
          title: documentTitle,
          createdAt: now,
          updatedAt: now,
          pages: pages,
          languageCode: language.code,
        );
        if (_settings.autoSaveHistory) {
          await _history.save(doc);
        }
        resultDocument = doc;
      } else {
        final docs = <ScanDocument>[];
        for (var i = 0; i < pages.length; i++) {
          final doc = ScanDocument(
            id: _uuid.v4(),
            title: pages.length > 1 ? '$documentTitle (${i + 1})' : documentTitle,
            createdAt: now,
            updatedAt: now,
            pages: [pages[i]],
            languageCode: language.code,
          );
          await _history.save(doc);
          docs.add(doc);
        }
        resultDocuments = docs;
      }

      stage = ProcessingStage.done;

      // Anonymous outcome metric — page count, script and whether any page
      // failed. Never the recognized text or image.
      unawaited(_analytics.logRecognitionCompleted(
        pageCount: pages.length,
        languageCode: language.code,
        hadFailure: pages.any((p) => p.hasRecognitionFailed),
      ));
    } catch (e) {
      stage = ProcessingStage.failed;
      errorMessage = e is AppException ? e.message : 'Something went wrong while processing your pages.';
      errorSuggestion = e is AppException ? e.suggestion : 'Please try again.';
    }
    notifyListeners();
  }

  bool _isGoodEnough(RecognitionOutcome outcome) {
    if (outcome.characterCount < _goodEnoughChars) return false;
    // Some devices don't report confidence at all; judging those pages by
    // confidence alone would disable the fast path entirely and make every
    // scan pay for enhancement it probably doesn't need.
    if (!outcome.hasConfidence) return outcome.characterCount >= _goodEnoughCharsNoConfidence;
    return outcome.confidence >= _goodEnoughConfidence;
  }

  Future<String> _persistPage(String workingPath, bool keepOriginal) async {
    if (!keepOriginal) {
      await _storage.deleteIfExists(workingPath);
      return '';
    }
    final dir = await _storage.documentsDir;
    final destination = '${dir.path}/${_uuid.v4()}.jpg';
    await File(workingPath).copy(destination);
    return destination;
  }
}
