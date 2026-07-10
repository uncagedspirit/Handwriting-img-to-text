/// A user-facing exception. [message] is always plain language, never a
/// stack trace or engine-specific term, so it can be shown directly in the UI.
class AppException implements Exception {
  const AppException(this.message, {this.suggestion, this.requiresAppSettings = false});

  final String message;
  final String? suggestion;

  /// When true, the fix requires the user to open the OS app-settings
  /// screen (e.g. a permanently denied permission).
  final bool requiresAppSettings;

  @override
  String toString() => message;
}
