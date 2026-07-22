import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/service_locator.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/file_storage.dart';
import '../../core/utils/image_enhancer.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/datasources/text_recognition_datasource.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/app_enums.dart';
import 'processing_args.dart';
import 'processing_controller.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key, required this.args});

  final ProcessingArgs args;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProcessingController(
        pageSpecs: args.pages,
        documentTitle: args.documentTitle,
        batchMode: args.batchMode,
        recognizer: locator<TextRecognitionDataSource>(),
        historyRepository: locator<HistoryRepository>(),
        settingsRepository: locator<SettingsRepository>(),
        fileStorage: locator<FileStorage>(),
        imageEnhancer: locator<ImageEnhancer>(),
      )..run(),
      child: const _ProcessingView(),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  void _cancel(BuildContext context) {
    context.read<ProcessingController>().cancel();
    Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProcessingController>();

    final isBusy = controller.stage != ProcessingStage.done && controller.stage != ProcessingStage.failed;

    return PopScope(
      canPop: !isBusy,
      onPopInvokedWithResult: (didPop, _) {
        // Back during processing cancels rather than being ignored.
        if (!didPop) _cancel(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Recognizing'), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _buildBody(context, controller),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProcessingController controller) {
    switch (controller.stage) {
      case ProcessingStage.preparing:
      case ProcessingStage.recognizing:
      case ProcessingStage.saving:
        return _ProgressView(
          progress: controller.progress,
          phaseLabel: controller.phaseLabel,
          pageNumber: controller.currentPageNumber,
          totalPages: controller.totalPages,
          onCancel: () => _cancel(context),
        );

      case ProcessingStage.failed:
        return EmptyState(
          icon: Icons.error_outline,
          title: "Recognition couldn't finish",
          message: controller.errorMessage,
          suggestion: controller.errorSuggestion,
          actionLabel: 'Go Back',
          onAction: () => Navigator.of(context).popUntil((r) => r.settings.name == AppRoutes.home),
        );

      case ProcessingStage.done:
        return _DoneView(controller: controller);
    }
  }
}

/// Engaging processing UI: a ring around a live percentage that counts up
/// smoothly (the number animates between the controller's discrete
/// sub-step updates so it never sits frozen), plus a phase label and a
/// linear bar.
class _ProgressView extends StatelessWidget {
  const _ProgressView({
    required this.progress,
    required this.phaseLabel,
    required this.pageNumber,
    required this.totalPages,
    required this.onCancel,
  });

  final double progress;
  final String phaseLabel;
  final int pageNumber;
  final int totalPages;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackColor = theme.brightness == Brightness.dark
        ? AppColors.darkSurfaceMuted
        : AppColors.lightSurfaceMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The whole dial animates toward each new target over ~450ms, so
        // both the ring and the counter move continuously rather than
        // snapping between sub-steps.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            final percent = (value * 100).round();
            return SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: trackColor,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  // Kept inside the ring at any system font scale.
                  SizedBox(
                    width: 116,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        // Phase text swaps with a soft fade so it reads as a live status,
        // not a flicker.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            phaseLabel,
            key: ValueKey(phaseLabel),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Page ${pageNumber.clamp(1, totalPages)} of $totalPages', style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: trackColor,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Everything runs on your device.',
          style: theme.textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.controller});

  final ProcessingController controller;

  @override
  Widget build(BuildContext context) {
    final merged = controller.batchMode == BatchMode.merge;
    final count = merged ? 1 : controller.resultDocuments.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Recognition complete', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          merged
              ? 'Your document is ready to review.'
              : '$count document${count == 1 ? '' : 's'} created and saved to History.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: 260,
          child: PrimaryButton(
            label: merged ? 'Review Text' : 'Go to History',
            icon: Icons.arrow_forward,
            onPressed: () {
              if (merged && controller.resultDocument != null) {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.review,
                  arguments: ReviewArgs(document: controller.resultDocument),
                );
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.history,
                  (route) => route.settings.name == AppRoutes.home,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
