import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/capture_datasource.dart';
import '../../data/datasources/text_recognition_datasource.dart';
import '../../data/repositories/export_repository.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../analytics/analytics_service.dart';
import '../utils/file_storage.dart';
import '../utils/image_enhancer.dart';
import '../utils/permission_helper.dart';

final GetIt locator = GetIt.instance;

const String historyBoxName = 'scan_history';

/// Wires up all repositories and data sources once at startup. Screens pull
/// dependencies from here instead of constructing them directly, keeping
/// data access swappable and out of the widget tree.
///
/// [analytics] is null when Firebase isn't available (init failed), which
/// keeps the app fully functional offline.
Future<void> setupLocator({FirebaseAnalytics? analytics}) async {
  await Hive.initFlutter();
  final historyBox = await Hive.openBox<Map>(historyBoxName);
  final prefs = await SharedPreferences.getInstance();

  final settings = SettingsRepository(prefs);
  final analyticsService = AnalyticsService(analytics);
  // Apply the user's stored opt-out before any event can be sent.
  await analyticsService.setEnabled(settings.analyticsEnabled);

  locator
    ..registerLazySingleton(() => FileStorage())
    ..registerLazySingleton(() => const ImageEnhancer())
    ..registerLazySingleton(() => const PermissionHelper())
    ..registerLazySingleton(() => TextRecognitionDataSource())
    ..registerLazySingleton(() => CaptureDataSource())
    ..registerLazySingleton(() => settings)
    ..registerLazySingleton(() => analyticsService)
    ..registerLazySingleton(() => HistoryRepository(historyBox))
    ..registerLazySingleton(() => ExportRepository(locator<FileStorage>()));
}
