import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Thin wrapper around Firebase Analytics. Logs only anonymous, aggregate
/// usage events — never document content, recognized text, image data, or
/// anything that could identify a user or their notes.
///
/// [analytics] is null when Firebase failed to initialize, so the app keeps
/// working offline and every call here is a safe no-op.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics? _analytics;

  /// Navigator observer that records screen views automatically. Falls back
  /// to a plain observer when analytics is unavailable.
  NavigatorObserver navigatorObserver() {
    final analytics = _analytics;
    if (analytics == null) return NavigatorObserver();
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  /// Honors the user's "share anonymous usage data" preference.
  Future<void> setEnabled(bool enabled) async {
    await _analytics?.setAnalyticsCollectionEnabled(enabled);
  }

  Future<void> logRecognitionCompleted({
    required int pageCount,
    required String languageCode,
    required bool hadFailure,
  }) async {
    await _analytics?.logEvent(
      name: 'recognition_completed',
      parameters: {
        'page_count': pageCount,
        'language': languageCode,
        'had_failure': hadFailure ? 1 : 0,
      },
    );
  }

  Future<void> logExport({required String format}) async {
    await _analytics?.logEvent(name: 'document_export', parameters: {'format': format});
  }
}
