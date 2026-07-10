import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/repositories/export_repository.dart';
import '../../domain/entities/app_enums.dart';

/// Presents export/share options for a document's recognized text.
Future<void> showExportSheet(
  BuildContext context, {
  required String text,
  required String fileName,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => _ExportSheet(text: text, fileName: fileName),
  );
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.text, required this.fileName});

  final String text;
  final String fileName;

  Future<void> _export(BuildContext context, ExportFormat format) async {
    final repo = locator<ExportRepository>();
    Navigator.of(context).pop();
    try {
      final file = await repo.exportToFile(text, fileName, format);
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export & Share', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _ExportTile(
              icon: Icons.description_outlined,
              label: 'Plain Text (.txt)',
              onTap: () => _export(context, ExportFormat.txt),
            ),
            _ExportTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF Document (.pdf)',
              onTap: () => _export(context, ExportFormat.pdf),
            ),
            _ExportTile(
              icon: Icons.article_outlined,
              label: 'Word Document (.docx)',
              onTap: () => _export(context, ExportFormat.docx),
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
  const _ExportTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
      onTap: onTap,
    );
  }
}
