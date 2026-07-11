import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/file_storage.dart';
import '../../core/utils/image_enhancer.dart';
import '../../data/datasources/text_recognition_datasource.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/scan_document.dart';
import '../../domain/entities/scan_page.dart';

enum ProcessingStage { preparing, recognizing, saving, done, failed }

/// Runs OCR across every prepared page and assembles the resulting
/// [ScanDocument](s), respecting the merge/separate batch choice and the
/// keep-original-image / auto-save-history settings.
class ProcessingController extends ChangeNotifier {
  ProcessingController({
    required this.imagePaths,
    required this.documentTitle,
    required this.batchMode,
    required TextRecognitionDataSource recognizer,
    required HistoryRepository historyRepository,
    required SettingsRepository settingsRepository,
    required FileStorage fileStorage,
    required ImageEnhancer imageEnhancer,
  })  : _recognizer = recognizer,
        _history = historyRepository,
        _settings = settingsRepository,
        _storage = fileStorage,
        _enhancer = imageEnhancer;

  final List<String> imagePaths;
  final String documentTitle;
  final BatchMode batchMode;

  final TextRecognitionDataSource _recognizer;
  final HistoryRepository _history;
  final SettingsRepository _settings;
  final FileStorage _storage;
  final ImageEnhancer _enhancer;
  final _uuid = const Uuid();

  ProcessingStage stage = ProcessingStage.preparing;
  int totalSteps = 0;
  int completedSteps = 0;
  String? errorMessage;
  String? errorSuggestion;

  /// The single merged document, populated when [batchMode] is merge.
  ScanDocument? resultDocument;

  /// The set of documents created, populated when [batchMode] is separate.
  List<ScanDocument> resultDocuments = const [];

  Future<void> run() async {
    // One step per page for enhancement (if enabled) plus one per page for
    // recognition, so the progress bar reflects the whole pipeline and never
    // sits still while heavy work happens off-screen.
    final autoEnhance = _settings.imageEnhancementEnabled;
    totalSteps = imagePaths.length * (autoEnhance ? 2 : 1);
    completedSteps = 0;
    stage = ProcessingStage.preparing;
    notifyListeners();

    final language = _settings.recognitionLanguage;
    final keepOriginal = _settings.keepOriginalImage;
    final now = DateTime.now();
    final pages = <ScanPage>[];

    try {
      final readyPaths = <String>[];
      for (final path in imagePaths) {
        if (autoEnhance) {
          final dir = await _storage.tempDir;
          final outputPath = '${dir.path}/${_uuid.v4()}.jpg';
          final enhanced = await _enhancer.autoEnhance(File(path), outputPath);
          readyPaths.add(enhanced.path);
          await _storage.deleteIfExists(path);
        } else {
          readyPaths.add(path);
        }
        completedSteps++;
        notifyListeners();
      }

      stage = ProcessingStage.recognizing;
      notifyListeners();

      for (final path in readyPaths) {
        String text;
        bool failed = false;
        try {
          text = await _recognizer.recognize(path, language);
        } on AppException {
          text = '';
          failed = true;
        }

        final persistedPath = await _persistPage(path, keepOriginal);
        pages.add(ScanPage(
          id: _uuid.v4(),
          imagePath: persistedPath,
          recognizedText: text,
          hasRecognitionFailed: failed,
        ));

        completedSteps++;
        notifyListeners();
      }

      stage = ProcessingStage.saving;
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
    } catch (e) {
      stage = ProcessingStage.failed;
      errorMessage = e is AppException ? e.message : 'Something went wrong while processing your pages.';
      errorSuggestion = e is AppException ? e.suggestion : 'Please try again.';
    }
    notifyListeners();
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
