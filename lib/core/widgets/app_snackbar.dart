import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Consistent, immediate feedback for user actions across the app.
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) => _show(context, message, AppColors.success, Icons.check_circle);

  static void error(BuildContext context, String message) => _show(context, message, AppColors.error, Icons.error_outline);

  static void info(BuildContext context, String message) => _show(context, message, AppColors.info, Icons.info_outline);

  /// Error feedback with an actionable button, e.g. "Open Settings" when a
  /// permission was permanently denied.
  static void errorWithAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          action: SnackBarAction(label: actionLabel, onPressed: onAction),
          duration: const Duration(seconds: 6),
        ),
      );
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
