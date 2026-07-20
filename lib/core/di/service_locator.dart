import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/capture_datasource.dart';
import '../../data/datasources/text_recognition_datasource.dart';
import '../../data/repositories/export_repository.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../utils/file_storage.dart';
import '../utils/image_enhancer.dart';
import '../utils/permission_helper.dart';

final GetIt locator = GetIt.instance;

const String historyBoxName = 'scan_history';

/// Wires up all repositories and data sources once at startup. Screens pull
/// dependencies from here instead of constructing them directly, keeping
/// data access swappable and out of the widget tree.
Future<void> setupLocator() async {
  await Hive.initFlutter();
  final historyBox = await Hive.openBox<Map>(historyBoxName);
  final prefs = await SharedPreferences.getInstance();

  locator
    ..registerLazySingleton(() => FileStorage())
    ..registerLazySingleton(() => const ImageEnhancer())
    ..registerLazySingleton(() => const PermissionHelper())
    ..registerLazySingleton(() => TextRecognitionDataSource())
    ..registerLazySingleton(() => CaptureDataSource())
    ..registerLazySingleton(() => SettingsRepository(prefs))
    ..registerLazySingleton(() => HistoryRepository(historyBox))
    ..registerLazySingleton(() => ExportRepository(locator<FileStorage>()));
}
