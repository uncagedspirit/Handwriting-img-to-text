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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProcessingController>();

    return PopScope(
      canPop: controller.stage == ProcessingStage.done || controller.stage == ProcessingStage.failed,
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
        final total = controller.totalSteps;
        final progress = total == 0 ? 0.0 : controller.completedSteps / total;
        final stageLabel = switch (controller.stage) {
          ProcessingStage.preparing => 'Enhancing your pages',
          ProcessingStage.saving => 'Saving your document',
          _ => 'Reading your handwriting',
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: total > 0 ? progress : null,
                    strokeWidth: 5,
                  ),
                  const Icon(Icons.document_scanner_outlined, color: AppColors.primary, size: 32),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(stageLabel, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              // completedSteps counts finished work, so the step currently
              // running is the next one — without the +1 users saw the
              // confusing "Step 0 of N" at the start.
              total > 1
                  ? 'Step ${(controller.completedSteps + 1).clamp(1, total)} of $total'
                  : 'This only takes a moment',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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
