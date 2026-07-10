import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Consistent, immediate feedback for user actions across the app.
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) => _show(context, message, AppColors.success, Icons.check_circle);

  static void error(BuildContext context, String message) => _show(context, message, AppColors.error, Icons.error_outline);

  static void info(BuildContext context, String message) => _show(context, message, AppColors.info, Icons.info_outline);

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
