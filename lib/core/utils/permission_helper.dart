import 'package:permission_handler/permission_handler.dart';

enum PermissionOutcome { granted, denied, permanentlyDenied }

/// Thin wrapper around `permission_handler` so screens can show a friendly,
/// actionable message instead of silently failing when a permission is
/// missing.
class PermissionHelper {
  const PermissionHelper();

  Future<PermissionOutcome> ensureCamera() => _ensure(Permission.camera);

  Future<PermissionOutcome> ensurePhotos() => _ensure(Permission.photos);

  Future<PermissionOutcome> _ensure(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return PermissionOutcome.granted;

    final result = await permission.request();
    if (result.isGranted || result.isLimited) return PermissionOutcome.granted;
    if (result.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    return PermissionOutcome.denied;
  }

  Future<void> openSettings() => openAppSettings();
}
