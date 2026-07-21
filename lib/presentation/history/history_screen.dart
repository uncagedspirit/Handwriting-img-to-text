import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/service_locator.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/rename_dialog.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/entities/scan_document.dart';
import '../common/document_list_tile.dart';
import 'history_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryController(locator<HistoryRepository>()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _rename(BuildContext context, ScanDocument doc) async {
    final controller = context.read<HistoryController>();
    final newTitle = await showRenameDialog(context, doc.title);
    if (newTitle != null) await controller.rename(doc, newTitle);
  }

  Future<void> _showActions(BuildContext context, ScanDocument doc) async {
    final controller = context.read<HistoryController>();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: Icon(doc.isFavorite ? Icons.star : Icons.star_border),
              title: Text(doc.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () => Navigator.of(context).pop('favorite'),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Select Multiple'),
              onTap: () => Navigator.of(context).pop('select'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'rename':
        await _rename(context, doc);
      case 'favorite':
        await controller.toggleFavorite(doc);
      case 'select':
        controller.enterSelectionMode(doc.id);
      case 'delete':
        await _delete(context, doc);
    }
  }

  Future<void> _delete(BuildContext context, ScanDocument doc) async {
    final controller = context.read<HistoryController>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Document?',
      message: 'This will permanently remove "${doc.title}".',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) await controller.delete(doc.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();

    return PopScope(
      // In selection mode, back should drop the selection rather than
      // leaving the screen entirely.
      canPop: !controller.selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.exitSelectionMode();
      },
      child: _buildScaffold(context, controller),
    );
  }

  Widget _buildScaffold(BuildContext context, HistoryController controller) {
    return Scaffold(
      appBar: AppBar(
        title: controller.selectionMode
            ? Text('${controller.selectedIds.length} selected')
            : const Text('History'),
        leading: controller.selectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: controller.exitSelectionMode)
            : null,
        actions: controller.selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete Documents?',
                      message: 'Delete ${controller.selectedIds.length} document(s)? This cannot be undone.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed) await controller.deleteSelected();
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: controller.isEmpty
            ? const EmptyState(
                icon: Icons.history,
                title: 'No history yet',
                message: 'Documents you convert will appear here so you can revisit them anytime.',
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: controller.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search documents',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  controller.setQuery('');
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: controller.filter == HistoryFilter.all,
                          onSelected: (_) => controller.setFilter(HistoryFilter.all),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: const Text('Favorites'),
                          selected: controller.filter == HistoryFilter.favorites,
                          onSelected: (_) => controller.setFilter(HistoryFilter.favorites),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: controller.documents.isEmpty
                        ? const EmptyState(icon: Icons.search_off, title: 'No matching documents')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.xl,
                            ),
                            itemCount: controller.documents.length,
                            itemBuilder: (context, index) {
                              final doc = controller.documents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Dismissible(
                                  key: ValueKey(doc.id),
                                  // Swiping rows away while multi-selecting
                                  // is ambiguous; the toolbar handles bulk
                                  // deletion in that mode.
                                  direction: controller.selectionMode
                                      ? DismissDirection.none
                                      : DismissDirection.endToStart,
                                  confirmDismiss: (_) => showConfirmDialog(
                                    context,
                                    title: 'Delete Document?',
                                    message: 'This will permanently remove "${doc.title}".',
                                    confirmLabel: 'Delete',
                                    isDestructive: true,
                                  ),
                                  onDismissed: (_) => controller.delete(doc.id),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.error,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete_outline, color: Colors.white),
                                  ),
                                  child: DocumentListTile(
                                    document: doc,
                                    selectionMode: controller.selectionMode,
                                    selected: controller.selectedIds.contains(doc.id),
                                    onFavoriteToggle: () => controller.toggleFavorite(doc),
                                    onLongPress: () => controller.selectionMode
                                        ? controller.toggleSelection(doc.id)
                                        : _showActions(context, doc),
                                    onTap: () async {
                                      if (controller.selectionMode) {
                                        controller.toggleSelection(doc.id);
                                        return;
                                      }
                                      await Navigator.of(context).pushNamed(
                                        AppRoutes.review,
                                        arguments: ReviewArgs(documentId: doc.id),
                                      );
                                      controller.refresh();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
