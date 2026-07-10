import 'package:flutter/material.dart';
import '../../domain/entities/scan_document.dart';
import '../../presentation/history/history_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/prepare/prepare_screen.dart';
import '../../presentation/processing/processing_args.dart';
import '../../presentation/processing/processing_screen.dart';
import '../../presentation/review/review_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import 'app_routes.dart';

/// Arguments carried into the prepare screen: raw image paths straight from
/// the camera or gallery, before any enhancement.
class PrepareArgs {
  const PrepareArgs({required this.imagePaths, required this.documentTitle});
  final List<String> imagePaths;
  final String documentTitle;
}

/// Arguments carried into the review screen. Either a brand-new document
/// fresh out of recognition, or an existing history entry being reopened.
class ReviewArgs {
  const ReviewArgs({this.document, this.documentId});
  final ScanDocument? document;
  final String? documentId;
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return _page(const OnboardingScreen(), settings);
      case AppRoutes.home:
        return _page(const HomeScreen(), settings);
      case AppRoutes.prepare:
        final args = settings.arguments as PrepareArgs;
        return _page(PrepareScreen(args: args), settings);
      case AppRoutes.processing:
        final args = settings.arguments as ProcessingArgs;
        return _page(ProcessingScreen(args: args), settings);
      case AppRoutes.review:
        final args = settings.arguments as ReviewArgs;
        return _page(ReviewScreen(args: args), settings);
      case AppRoutes.history:
        return _page(const HistoryScreen(), settings);
      case AppRoutes.settings:
        return _page(const SettingsScreen(), settings);
      default:
        return _page(const HomeScreen(), settings);
    }
  }

  static PageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}
