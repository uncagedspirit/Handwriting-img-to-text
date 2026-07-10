import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/app_enums.dart';

/// Exposes user preferences to the UI and persists changes immediately.
/// Also drives the app's [ThemeMode] so toggling dark mode applies instantly.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  RecognitionLanguage get recognitionLanguage => _repository.recognitionLanguage;
  ExportFormat get defaultExportFormat => _repository.defaultExportFormat;
  bool get keepOriginalImage => _repository.keepOriginalImage;
  bool get autoSaveHistory => _repository.autoSaveHistory;
  ThemeModePreference get themeModePreference => _repository.themeMode;
  bool get imageEnhancementEnabled => _repository.imageEnhancementEnabled;
  bool get defaultShareAsPlainText => _repository.defaultShareAsPlainText;
  bool get exportToDownloads => _repository.exportToDownloads;
  bool get onboardingSeen => _repository.onboardingSeen;

  ThemeMode get themeMode {
    switch (themeModePreference) {
      case ThemeModePreference.system:
        return ThemeMode.system;
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
    }
  }

  Future<void> setRecognitionLanguage(RecognitionLanguage language) async {
    await _repository.setRecognitionLanguage(language);
    notifyListeners();
  }

  Future<void> setDefaultExportFormat(ExportFormat format) async {
    await _repository.setDefaultExportFormat(format);
    notifyListeners();
  }

  Future<void> setKeepOriginalImage(bool value) async {
    await _repository.setKeepOriginalImage(value);
    notifyListeners();
  }

  Future<void> setAutoSaveHistory(bool value) async {
    await _repository.setAutoSaveHistory(value);
    notifyListeners();
  }

  Future<void> setThemeModePreference(ThemeModePreference mode) async {
    await _repository.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setImageEnhancementEnabled(bool value) async {
    await _repository.setImageEnhancementEnabled(value);
    notifyListeners();
  }

  Future<void> setDefaultShareAsPlainText(bool value) async {
    await _repository.setDefaultShareAsPlainText(value);
    notifyListeners();
  }

  Future<void> setExportToDownloads(bool value) async {
    await _repository.setExportToDownloads(value);
    notifyListeners();
  }

  Future<void> setOnboardingSeen(bool value) async {
    await _repository.setOnboardingSeen(value);
    notifyListeners();
  }
}
