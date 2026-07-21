import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_exception.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../data/datasources/capture_datasource.dart';
import '../../data/repositories/history_repository.dart';
import '../common/document_list_tile.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(
        captureDataSource: locator<CaptureDataSource>(),
        historyRepository: locator<HistoryRepository>(),
        permissionHelper: locator(),
      ),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final List<String> _stagedImages = [];

  Future<void> _addFromCamera() async {
    final controller = context.read<HomeController>();
    try {
      final path = await controller.captureFromCamera();
      if (path != null) setState(() => _stagedImages.add(path));
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.requiresAppSettings) {
        AppSnackBar.errorWithAction(
          context,
          e.message,
          actionLabel: 'Open Settings',
          onAction: controller.openAppSettings,
        );
      } else {
        AppSnackBar.error(context, e.message);
      }
    }
  }

  Future<void> _addFromGallery() async {
    final controller = context.read<HomeController>();
    try {
      final paths = await controller.pickFromGallery();
      if (paths.isNotEmpty) setState(() => _stagedImages.addAll(paths));
    } on AppException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  void _removeStaged(int index) => setState(() => _stagedImages.removeAt(index));

  void _clearStaged() => setState(() => _stagedImages.clear());

  Future<void> _continue() async {
    if (_stagedImages.isEmpty) return;
    final images = List<String>.of(_stagedImages);
    _clearStaged();
    final title = _defaultTitle();
    if (!mounted) return;
    // The prepare screen completes this future with `true` only when it
    // hands off to recognition. Any other outcome means the user backed
    // out — restore their staged pages instead of throwing away what they
    // just captured.
    final proceeded = await Navigator.of(context).pushNamed(
      AppRoutes.prepare,
      arguments: PrepareArgs(imagePaths: images, documentTitle: title),
    );
    if (!mounted) return;
    if (proceeded != true) {
      setState(() => _stagedImages.addAll(images.where((p) => File(p).existsSync())));
    }
    context.read<HomeController>().refreshRecent();
  }

  /// Includes the time, not just the date — scanning several pages in one
  /// day previously produced a list of identically named documents that
  /// were impossible to tell apart in History.
  String _defaultTitle() => 'Scan ${DateFormat('d MMM, h:mm a').format(DateTime.now())}';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      appBar: AppBar(
        // Sourced from AppConfig so renaming the product is a one-line change.
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => controller.refreshRecent(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              _CaptureCard(onCamera: _addFromCamera, onGallery: _addFromGallery),
              if (_stagedImages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _StagedPagesSection(
                  imagePaths: _stagedImages,
                  onRemove: _removeStaged,
                  onAddMore: _addFromCamera,
                  onClear: _clearStaged,
                  onContinue: _continue,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Recent',
                trailing: controller.recentDocuments.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
                        child: const Text('See all'),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (controller.recentDocuments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No conversions yet',
                    message: 'Capture or import a handwritten page to get started.',
                  ),
                )
              else
                ...controller.recentDocuments.map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DocumentListTile(
                      document: doc,
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          AppRoutes.review,
                          arguments: ReviewArgs(documentId: doc.id),
                        );
                        controller.refreshRecent();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Convert handwriting to text', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Everything runs on your device. Your documents are never uploaded.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(label: 'Take Photo', icon: Icons.camera_alt_outlined, onPressed: onCamera),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Import from Gallery',
                    icon: Icons.photo_library_outlined,
                    onPressed: onGallery,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StagedPagesSection extends StatelessWidget {
  const _StagedPagesSection({
    required this.imagePaths,
    required this.onRemove,
    required this.onAddMore,
    required this.onClear,
    required this.onContinue,
  });

  final List<String> imagePaths;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddMore;
  final VoidCallback onClear;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '${imagePaths.length} page${imagePaths.length == 1 ? '' : 's'} ready',
              trailing: TextButton(onPressed: onClear, child: const Text('Clear')),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagePaths.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == imagePaths.length) {
                    return InkWell(
                      onTap: onAddMore,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary),
                      ),
                    );
                  }
                  final path = imagePaths[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          width: 72,
                          height: 88,
                          fit: BoxFit.cover,
                          // Staged pages are full-size captures; decode them
                          // down rather than caching whole bitmaps per strip.
                          cacheWidth: (72 * MediaQuery.devicePixelRatioOf(context)).round(),
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, _) => Container(
                            width: 72,
                            height: 88,
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.primary),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton(
                          onPressed: () => onRemove(index),
                          icon: const Icon(Icons.cancel, size: 20, color: AppColors.error),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
