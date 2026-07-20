import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/service_locator.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/scan_document.dart';
import '../export/export_sheet.dart';
import 'review_controller.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.args});

  final ReviewArgs args;

  @override
  Widget build(BuildContext context) {
    final ScanDocument? document = args.document ?? locator<HistoryRepository>().getById(args.documentId ?? '');

    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'This document is no longer available',
          message: 'It may have been deleted.',
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) {
        final controller = ReviewController(
          document: document,
          historyRepository: locator<HistoryRepository>(),
          settingsRepository: locator<SettingsRepository>(),
        );
        controller.initListeners();
        if (args.document != null) controller.autoSaveIfEnabled();
        if (args.documentId != null) controller.isSaved = true;
        return controller;
      },
      child: const _ReviewView(),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView();

  Future<void> _rename(BuildContext context) async {
    final controller = context.read<ReviewController>();
    final textController = TextEditingController(text: controller.document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(controller: textController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.trim().isNotEmpty) {
      await controller.rename(newTitle);
    }
  }

  Future<void> _searchReplace(BuildContext context) async {
    final controller = context.read<ReviewController>();
    final searchController = TextEditingController();
    final replaceController = TextEditingController();
    final count = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find & Replace', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: searchController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Find'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: replaceController,
              decoration: const InputDecoration(hintText: 'Replace with'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final replaced = controller.replaceAll(searchController.text, replaceController.text);
                  Navigator.of(sheetContext).pop(replaced);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Replace All'),
              ),
            ),
          ],
        ),
      ),
    );
    // Feedback must use the screen's own context: the sheet's context is
    // deactivated once it pops, which previously made the result toast
    // silently fail.
    if (count != null && context.mounted) {
      AppSnackBar.info(
        context,
        count == 0 ? 'No matches found' : 'Replaced $count occurrence${count == 1 ? '' : 's'}',
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final controller = context.read<ReviewController>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Document?',
      message: 'This will permanently remove "${controller.document.title}" from your history.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      await controller.delete();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReviewController>();
    final document = controller.document;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _rename(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(document.title, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: controller.toggleFavorite,
            icon: Icon(
              document.isFavorite ? Icons.star : Icons.star_border,
              color: document.isFavorite ? AppColors.warning : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'search':
                  _searchReplace(context);
                case 'select_all':
                  controller.selectAll();
                case 'delete':
                  _delete(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'search', child: Text('Find & Replace')),
              PopupMenuItem(value: 'select_all', child: Text('Select All')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (controller.hasKeptImages)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: SegmentedButton<ReviewViewMode>(
                  segments: const [
                    ButtonSegment(value: ReviewViewMode.text, label: Text('Text'), icon: Icon(Icons.notes)),
                    ButtonSegment(value: ReviewViewMode.split, label: Text('Compare'), icon: Icon(Icons.vertical_split)),
                    ButtonSegment(value: ReviewViewMode.image, label: Text('Original'), icon: Icon(Icons.image_outlined)),
                  ],
                  selected: {controller.viewMode},
                  onSelectionChanged: (s) => controller.setViewMode(s.first),
                ),
              ),
            if (document.hasAnyFailure)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'One or more pages could not be fully recognized.',
                        style: TextStyle(color: AppColors.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildBody(context, controller)),
            _BottomActions(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReviewController controller) {
    switch (controller.viewMode) {
      case ReviewViewMode.text:
        return _TextEditor(controller: controller);
      case ReviewViewMode.image:
        return _ImageViewer(controller: controller);
      case ReviewViewMode.split:
        return Column(
          children: [
            Expanded(child: _ImageViewer(controller: controller)),
            const Divider(height: 1),
            Expanded(child: _TextEditor(controller: controller)),
          ],
        );
    }
  }
}

class _TextEditor extends StatelessWidget {
  const _TextEditor({required this.controller});
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: controller.textController,
        undoController: controller.undoController,
        focusNode: controller.editorFocusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: const InputDecoration(
          hintText: 'Recognized text will appear here',
          filled: false,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.controller});
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    final pages = controller.document.pages;
    if (!controller.hasKeptImages) {
      return const EmptyState(
        icon: Icons.image_not_supported_outlined,
        title: 'Original image not kept',
        message: 'Enable "Keep original image" in Settings to compare with the source page.',
      );
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: pages.length,
            controller: PageController(initialPage: controller.imagePageIndex),
            onPageChanged: controller.setImagePageIndex,
            itemBuilder: (context, index) {
              final path = pages[index].imagePath;
              if (path.isEmpty || !File(path).existsSync()) {
                return const Center(child: Icon(Icons.broken_image_outlined, size: 48));
              }
              return InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain));
            },
          ),
        ),
        if (pages.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('Page ${controller.imagePageIndex + 1} of ${pages.length}'),
          ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.controller});
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // The undo controller is a ValueListenable, not part of the
          // ChangeNotifier — without listening to it directly these buttons
          // never left their initial disabled state.
          ValueListenableBuilder<UndoHistoryValue>(
            valueListenable: controller.undoController,
            builder: (context, undoValue, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Undo',
                  onPressed: undoValue.canUndo ? () => controller.undoController.undo() : null,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: 'Redo',
                  onPressed: undoValue.canRedo ? () => controller.undoController.redo() : null,
                  icon: const Icon(Icons.redo),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () async {
              await controller.save();
              if (context.mounted) AppSnackBar.success(context, 'Saved');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight, foregroundColor: AppColors.primary),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => showExportSheet(
              context,
              text: controller.document.displayText,
              fileName: controller.document.title,
            ),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
