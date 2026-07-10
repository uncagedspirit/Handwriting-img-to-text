import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/settings/settings_controller.dart';

class HandwritingApp extends StatelessWidget {
  const HandwritingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsController(locator<SettingsRepository>()),
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            initialRoute: settings.onboardingSeen ? AppRoutes.home : AppRoutes.onboarding,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
