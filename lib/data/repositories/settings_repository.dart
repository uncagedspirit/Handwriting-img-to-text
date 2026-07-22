import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_enums.dart';

/// Persists user preferences with [SharedPreferences]. All settings have
/// sensible defaults so a fresh install works without configuration.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kLanguage = 'settings.recognitionLanguage';
  static const _kExportFormat = 'settings.defaultExportFormat';
  static const _kKeepOriginal = 'settings.keepOriginalImage';
  static const _kAutoSaveHistory = 'settings.autoSaveHistory';
  static const _kThemeMode = 'settings.themeMode';
  static const _kEnhancement = 'settings.imageEnhancementEnabled';
  static const _kShareAsText = 'settings.defaultShareAsPlainText';
  static const _kOnboardingSeen = 'settings.onboardingSeen';
  static const _kExportToDownloads = 'settings.exportToDownloads';
  static const _kAnalyticsEnabled = 'settings.analyticsEnabled';

  RecognitionLanguage get recognitionLanguage =>
      RecognitionLanguage.fromCode(_prefs.getString(_kLanguage) ?? RecognitionLanguage.latin.code);

  Future<void> setRecognitionLanguage(RecognitionLanguage language) =>
      _prefs.setString(_kLanguage, language.code);

  ExportFormat get defaultExportFormat =>
      ExportFormat.fromExtension(_prefs.getString(_kExportFormat) ?? ExportFormat.pdf.extension);

  Future<void> setDefaultExportFormat(ExportFormat format) =>
      _prefs.setString(_kExportFormat, format.extension);

  bool get keepOriginalImage => _prefs.getBool(_kKeepOriginal) ?? true;

  Future<void> setKeepOriginalImage(bool value) => _prefs.setBool(_kKeepOriginal, value);

  bool get autoSaveHistory => _prefs.getBool(_kAutoSaveHistory) ?? true;

  Future<void> setAutoSaveHistory(bool value) => _prefs.setBool(_kAutoSaveHistory, value);

  ThemeModePreference get themeMode =>
      ThemeModePreference.fromCode(_prefs.getString(_kThemeMode) ?? ThemeModePreference.system.code);

  Future<void> setThemeMode(ThemeModePreference mode) => _prefs.setString(_kThemeMode, mode.code);

  bool get imageEnhancementEnabled => _prefs.getBool(_kEnhancement) ?? true;

  Future<void> setImageEnhancementEnabled(bool value) => _prefs.setBool(_kEnhancement, value);

  /// When true, the share sheet is pre-filled with plain text; when false it
  /// shares the exported file (using [defaultExportFormat]).
  bool get defaultShareAsPlainText => _prefs.getBool(_kShareAsText) ?? true;

  Future<void> setDefaultShareAsPlainText(bool value) => _prefs.setBool(_kShareAsText, value);

  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) => _prefs.setBool(_kOnboardingSeen, value);

  /// When true, exported files are written to the public Downloads folder
  /// in addition to the app's private export folder, so they're easy to
  /// find in other apps. When false, exports stay app-private and are only
  /// reachable via Share.
  bool get exportToDownloads => _prefs.getBool(_kExportToDownloads) ?? true;

  Future<void> setExportToDownloads(bool value) => _prefs.setBool(_kExportToDownloads, value);

  /// When true, the app sends anonymous usage metrics via Firebase
  /// Analytics. Never includes document content, images, or recognized
  /// text. Users can opt out in Settings.
  bool get analyticsEnabled => _prefs.getBool(_kAnalyticsEnabled) ?? true;

  Future<void> setAnalyticsEnabled(bool value) => _prefs.setBool(_kAnalyticsEnabled, value);
}
