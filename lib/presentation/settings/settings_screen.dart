import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/entities/app_enums.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SectionHeader(title: 'Recognition'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.translate_outlined,
                  title: 'Recognition Language',
                  subtitle: settings.recognitionLanguage.label,
                  onTap: () => _pickLanguage(context, settings),
                ),
                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.auto_fix_high_outlined,
                  title: 'Image Enhancement',
                  subtitle: 'Automatically improve contrast and sharpness',
                  value: settings.imageEnhancementEnabled,
                  onChanged: settings.setImageEnhancementEnabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Export'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.file_present_outlined,
                  title: 'Default Export Format',
                  subtitle: settings.defaultExportFormat.label,
                  onTap: () => _pickExportFormat(context, settings),
                ),
                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.download_outlined,
                  title: 'Save Exports to Downloads',
                  subtitle: 'Also save a copy to your Downloads folder',
                  value: settings.exportToDownloads,
                  onChanged: settings.setExportToDownloads,
                ),
                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.share_outlined,
                  title: 'Share as Plain Text by Default',
                  subtitle: 'Prefer sharing text directly instead of a file',
                  value: settings.defaultShareAsPlainText,
                  onChanged: settings.setDefaultShareAsPlainText,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Documents'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _SwitchTile(
                  icon: Icons.image_outlined,
                  title: 'Keep Original Image',
                  subtitle: 'Store the captured page alongside recognized text',
                  value: settings.keepOriginalImage,
                  onChanged: settings.setKeepOriginalImage,
                ),
                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.save_outlined,
                  title: 'Auto-save History',
                  subtitle: 'Automatically save new conversions to History',
                  value: settings.autoSaveHistory,
                  onChanged: settings.setAutoSaveHistory,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Appearance'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  subtitle: settings.themeModePreference.label,
                  onTap: () => _pickTheme(context, settings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'About'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.info_outline,
                  title: AppConfig.appName,
                  subtitle: 'Version ${AppConfig.appVersion}',
                  onTap: () {},
                  showChevron: false,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showDocument(context, 'Privacy Policy', _privacyPolicyText),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _showDocument(context, 'Terms & Conditions', _termsText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, SettingsController settings) async {
    final selected = await showModalBottomSheet<RecognitionLanguage>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RecognitionLanguage.values
              .map((lang) => ListTile(
                    title: Text(lang.label),
                    subtitle: Text(lang.description),
                    trailing: lang == settings.recognitionLanguage
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(lang),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) await settings.setRecognitionLanguage(selected);
  }

  Future<void> _pickExportFormat(BuildContext context, SettingsController settings) async {
    final selected = await showModalBottomSheet<ExportFormat>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExportFormat.values
              .map((format) => ListTile(
                    title: Text(format.label),
                    trailing: format == settings.defaultExportFormat
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(format),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) await settings.setDefaultExportFormat(selected);
  }

  Future<void> _pickTheme(BuildContext context, SettingsController settings) async {
    final selected = await showModalBottomSheet<ThemeModePreference>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeModePreference.values
              .map((mode) => ListTile(
                    title: Text(mode.label),
                    trailing: mode == settings.themeModePreference
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(mode),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) await settings.setThemeModePreference(selected);
  }

  void _showDocument(BuildContext context, String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(content, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: showChevron ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

const _privacyPolicyText = '''
Your privacy matters. This app is designed to work entirely on your device.

What we do:
- All handwriting recognition happens locally on your phone. Your images and text are never uploaded to any server.
- Captured images and recognized text are stored only on your device, inside the app's private storage.
- The camera and photo library are accessed only when you choose to capture or import a page.

Analytics:
- This app may use Firebase Analytics to understand general, anonymous usage patterns (such as which features are used) so we can improve the app. Analytics data does not include your handwritten content, images, or recognized text.

Your control:
- You can delete any document from History at any time.
- You can disable "Keep Original Image" in Settings so captured pages are not retained after recognition.
- Uninstalling the app removes all locally stored data.

We do not sell or share your personal documents with any third party.
''';

const _termsText = '''
By using this app, you agree to the following:

1. This app is provided as a utility to help you convert handwritten pages into editable text. Recognition accuracy depends on handwriting clarity, lighting, and image quality, and is not guaranteed to be perfect.

2. You are responsible for the content you capture and export. Do not use this app to process content you do not have the right to digitize.

3. The app works offline and stores data locally on your device. You are responsible for backing up any documents you wish to keep permanently.

4. The app is provided "as is" without warranties of any kind. We are not liable for any loss of data or damages arising from use of the app.

5. These terms may be updated from time to time. Continued use of the app after changes constitutes acceptance of the updated terms.
''';
