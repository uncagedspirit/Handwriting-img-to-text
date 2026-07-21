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
import '../../core/widgets/rename_dialog.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/scan_document.dart';
import '../export/export_sheet.dart';
import 'find_replace_sheet.dart';
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
    final newTitle = await showRenameDialog(context, controller.document.title);
    if (newTitle != null) await controller.rename(newTitle);
  }

  Future<void> _searchReplace(BuildContext context) async {
    final controller = context.read<ReviewController>();
    final request = await showFindReplaceSheet(context);
    if (request == null || !context.mounted) return;

    final count = controller.replaceAll(request.search, request.replacement);
    // Feedback must use the screen's own context: the sheet's context is
    // deactivated once it pops, which previously made the result toast
    // silently fail.
    AppSnackBar.info(
      context,
      count == 0 ? 'No matches found' : 'Replaced $count occurrence${count == 1 ? '' : 's'}',
    );
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

  /// Guards against silently discarding edits. Returns true when it is safe
  /// to leave the screen.
  Future<bool> _confirmDiscard(BuildContext context) async {
    final controller = context.read<ReviewController>();
    if (!controller.isDirty) return true;

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('You have edits that have not been saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (choice == 'save') {
      await controller.save();
      return true;
    }
    return choice == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReviewController>();
    final document = controller.document;

    return PopScope(
      canPop: !controller.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildScaffold(context, controller, document),
    );
  }

  Widget _buildScaffold(BuildContext context, ReviewController controller, ScanDocument document) {
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
            tooltip: 'Share',
            onPressed: () => quickShare(
              context,
              text: controller.document.displayText,
              fileName: controller.document.title,
            ),
            icon: const Icon(Icons.share_outlined),
          ),
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

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.controller});
  final ReviewController controller;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Built once and disposed properly: creating this inside build leaked a
    // controller on every rebuild and fought with the user's own swipes.
    _pageController = PageController(initialPage: widget.controller.imagePageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
            controller: _pageController,
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
