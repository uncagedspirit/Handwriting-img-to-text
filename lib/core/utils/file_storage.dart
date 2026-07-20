import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/app_config.dart';

/// Resolves and prepares the app's private storage folders. All document
/// images and exports live under the app's own documents directory —
/// nothing is uploaded anywhere.
class FileStorage {
  Future<Directory> get documentsDir async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/${AppConfig.documentsFolderName}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get exportsDir async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/${AppConfig.exportsFolderName}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get tempDir async => getTemporaryDirectory();

  Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
