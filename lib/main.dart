import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Never show Flutter's raw red/grey error screen to end users: fall back
  // to a plain-language message instead, per the app's error-handling policy.
  ErrorWidget.builder = (details) => Material(
        color: AppColors.lightBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline, color: AppColors.error, size: 40),
                SizedBox(height: 12),
                Text(
                  "Something went wrong displaying this screen.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.lightTextPrimary),
                ),
              ],
            ),
          ),
        ),
      );

  runApp(const HandwritingApp());
}
