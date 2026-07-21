import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/scan_document.dart';

/// A single recognition entry, used on Home (recents) and the History list.
class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.selected = false,
    this.selectionMode = false,
    this.onLongPress,
  });

  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onLongPress;

  static const double _thumbnailSize = 56;

  Widget _placeholder() => Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.description_outlined, color: AppColors.primary),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailPath = document.pages.isNotEmpty ? document.pages.first.imagePath : null;
    // Deliberately no existsSync() here: synchronous file I/O in build runs
    // on the UI thread for every row on every rebuild. A missing file is
    // handled by errorBuilder instead.
    final thumbnailFile = (thumbnailPath != null && thumbnailPath.isNotEmpty) ? File(thumbnailPath) : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : theme.colorScheme.outline,
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  child: thumbnailFile == null
                      ? _placeholder()
                      : Image.file(
                          thumbnailFile,
                          fit: BoxFit.cover,
                          // Decode straight to thumbnail size. Without this
                          // every row held a full-resolution bitmap in the
                          // image cache — tens of megabytes per screen.
                          cacheWidth: (_thumbnailSize * MediaQuery.devicePixelRatioOf(context)).round(),
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, _) => _placeholder(),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat.yMMMd().add_jm().format(document.updatedAt)} · ${document.pages.length} page${document.pages.length == 1 ? '' : 's'}',
                      style: theme.textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!selectionMode && onFavoriteToggle != null)
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    document.isFavorite ? Icons.star : Icons.star_border,
                    color: document.isFavorite ? AppColors.warning : theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
