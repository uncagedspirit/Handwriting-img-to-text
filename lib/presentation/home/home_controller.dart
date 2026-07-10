import 'package:flutter/material.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/permission_helper.dart';
import '../../data/datasources/capture_datasource.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/entities/scan_document.dart';

/// Business logic for the Home screen: recent documents and capture entry
/// points (camera / gallery / batch).
class HomeController extends ChangeNotifier {
  HomeController({
    required CaptureDataSource captureDataSource,
    required HistoryRepository historyRepository,
    required PermissionHelper permissionHelper,
  })  : _capture = captureDataSource,
        _history = historyRepository,
        _permissions = permissionHelper {
    refreshRecent();
  }

  final CaptureDataSource _capture;
  final HistoryRepository _history;
  final PermissionHelper _permissions;

  List<ScanDocument> recentDocuments = [];

  void refreshRecent() {
    final all = _history.getAll();
    recentDocuments = all.take(5).toList();
    notifyListeners();
  }

  Future<String?> captureFromCamera() async {
    final outcome = await _permissions.ensureCamera();
    if (outcome != PermissionOutcome.granted) {
      throw AppException(
        outcome == PermissionOutcome.permanentlyDenied
            ? 'Camera access is turned off for this app.'
            : 'Camera access is needed to capture handwriting.',
        suggestion: outcome == PermissionOutcome.permanentlyDenied
            ? 'Enable it from your phone Settings.'
            : 'Allow camera access when prompted.',
        requiresAppSettings: outcome == PermissionOutcome.permanentlyDenied,
      );
    }
    return _capture.captureFromCamera();
  }

  Future<List<String>> pickFromGallery({bool allowMultiple = true}) async {
    return _capture.pickFromGallery(allowMultiple: allowMultiple);
  }

  Future<void> openAppSettings() => _permissions.openSettings();
}
