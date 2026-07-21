import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/repositories/export_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/app_enums.dart';

/// Presents export/share options for a document's recognized text. The
/// user's default export format (from Settings) is listed first and tagged.
Future<void> showExportSheet(
  BuildContext context, {
  required String text,
  required String fileName,
}) async {
  // A page whose recognition found nothing has no text to export, and
  // share_plus rejects empty content outright.
  if (text.trim().isEmpty) {
    AppSnackBar.info(context, 'There is no text to export yet');
    return;
  }
  return showModalBottomSheet(
    context: context,
    builder: (context) => _ExportSheet(text: text, fileName: fileName),
  );
}

/// Shares using the behavior chosen in Settings: plain text directly, or a
/// file in the default export format. Used by the review screen's quick
/// share action.
Future<void> quickShare(BuildContext context, {required String text, required String fileName}) async {
  if (text.trim().isEmpty) {
    AppSnackBar.info(context, 'There is no text to share yet');
    return;
  }
  final repo = locator<ExportRepository>();
  final settings = locator<SettingsRepository>();
  if (settings.defaultShareAsPlainText) {
    await repo.shareText(text, subject: fileName);
    return;
  }
  try {
    final file = await repo.exportToFile(
      text,
      fileName,
      settings.defaultExportFormat,
      copyToDownloads: settings.exportToDownloads,
    );
    await repo.shareFile(file);
  } catch (_) {
    if (context.mounted) {
      AppSnackBar.error(context, "We couldn't share this document. Please try again.");
    }
  }
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.text, required this.fileName});

  final String text;
  final String fileName;

  Future<void> _export(BuildContext context, ExportFormat format) async {
    final repo = locator<ExportRepository>();
    final settings = locator<SettingsRepository>();
    Navigator.of(context).pop();
    try {
      final file = await repo.exportToFile(
        text,
        fileName,
        format,
        copyToDownloads: settings.exportToDownloads,
      );
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Saved as ${format.label}');
      await repo.shareFile(file);
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.error(context, "We couldn't export this document. Please try again.");
      }
    }
  }

  Future<void> _copy(BuildContext context) async {
    final repo = locator<ExportRepository>();
    await repo.copyToClipboard(text);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    AppSnackBar.success(context, 'Copied to clipboard');
  }

  Future<void> _share(BuildContext context) async {
    final repo = locator<ExportRepository>();
    Navigator.of(context).pop();
    await repo.shareText(text, subject: fileName);
  }

  IconData _iconFor(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt:
        return Icons.description_outlined;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
      case ExportFormat.docx:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultFormat = locator<SettingsRepository>().defaultExportFormat;
    // Default format first, so one tap covers the common case.
    final formats = [
      defaultFormat,
      ...ExportFormat.values.where((f) => f != defaultFormat),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export & Share', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final format in formats)
              _ExportTile(
                icon: _iconFor(format),
                label: format.label,
                isDefault: format == defaultFormat,
                onTap: () => _export(context, format),
              ),
            const Divider(height: AppSpacing.lg),
            _ExportTile(
              icon: Icons.copy_outlined,
              label: 'Copy to Clipboard',
              onTap: () => _copy(context),
            ),
            _ExportTile(
              icon: Icons.ios_share_outlined,
              label: 'Share Text',
              onTap: () => _share(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDefault = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(label),
      trailing: isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Default',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
