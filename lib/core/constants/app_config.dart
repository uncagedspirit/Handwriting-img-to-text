/// Single source of truth for branding strings used throughout the app.
///
/// The Android app label lives separately in
/// `android/app/src/main/res/values/strings.xml`. Update both places when
/// renaming the product.
class AppConfig {
  AppConfig._();

  static const String appName = 'Handwriting Image to Text';
  static const String appVersion = '1.0.0';

  /// Folder name (under the app's document directory) where kept original
  /// images and exported files are stored.
  static const String documentsFolderName = 'documents';
  static const String exportsFolderName = 'exports';
}
