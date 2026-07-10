/// A user-facing exception. [message] is always plain language, never a
/// stack trace or engine-specific term, so it can be shown directly in the UI.
class AppException implements Exception {
  const AppException(this.message, {this.suggestion});

  final String message;
  final String? suggestion;

  @override
  String toString() => message;
}
