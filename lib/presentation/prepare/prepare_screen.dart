import 'dart:io';
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
import '../../data/datasources/crop_datasource.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/app_enums.dart';
import '../processing/processing_args.dart';
import 'prepare_controller.dart';

class PrepareScreen extends StatelessWidget {
  const PrepareScreen({super.key, required this.args});

  final PrepareArgs args;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrepareController(
        imagePaths: args.imagePaths,
        imageEnhancer: locator<ImageEnhancer>(),
        cropDataSource: locator<CropDataSource>(),
        fileStorage: locator<FileStorage>(),
      ),
      child: _PrepareView(documentTitle: args.documentTitle),
    );
  }
}

class _PrepareView extends StatefulWidget {
  const _PrepareView({required this.documentTitle});
  final String documentTitle;

  @override
  State<_PrepareView> createState() => _PrepareViewState();
}

class _PrepareViewState extends State<_PrepareView> {
  bool _adjustExpanded = false;

  Future<void> _proceed() async {
    final controller = context.read<PrepareController>();
    final settings = locator<SettingsRepository>();

    var batchMode = BatchMode.merge;
    if (controller.pages.length > 1) {
      final chosen = await _askBatchMode(context);
      if (chosen == null) return;
      batchMode = chosen;
    }

    final finalPaths = await controller.finalizeAll(autoEnhance: settings.imageEnhancementEnabled);
    if (!mounted) return;

    await Navigator.of(context).pushReplacementNamed(
      AppRoutes.processing,
      arguments: ProcessingArgs(
        imagePaths: finalPaths,
        documentTitle: widget.documentTitle,
        batchMode: batchMode,
      ),
    );
  }

  Future<BatchMode?> _askBatchMode(BuildContext context) {
    return showModalBottomSheet<BatchMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Multiple pages captured', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'How should these pages be processed?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.merge_type, color: AppColors.primary),
                title: const Text('Merge into one document'),
                subtitle: const Text('All pages become one recognition with combined text'),
                onTap: () => Navigator.of(context).pop(BatchMode.merge),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dynamic_feed, color: AppColors.primary),
                title: const Text('Keep as separate documents'),
                subtitle: const Text('Each page is saved as its own history entry'),
                onTap: () => Navigator.of(context).pop(BatchMode.separate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PrepareController>();
    final page = controller.current;

    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${controller.currentIndex + 1} of ${controller.pages.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(File(page.workingPath), fit: BoxFit.contain),
                  ),
                  if (controller.isBusy)
                    Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(
                        icon: Icons.crop,
                        label: 'Crop',
                        onTap: controller.isBusy ? null : controller.cropCurrent,
                      ),
                      _ToolButton(
                        icon: Icons.rotate_90_degrees_ccw_outlined,
                        label: 'Rotate',
                        onTap: controller.isBusy ? null : controller.rotateCurrent,
                      ),
                      _ToolButton(
                        icon: Icons.tune,
                        label: 'Adjust',
                        onTap: () => setState(() => _adjustExpanded = !_adjustExpanded),
                        selected: _adjustExpanded,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _adjustExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                      child: Column(
                        children: [
                          _AdjustSlider(
                            label: 'Brightness',
                            value: page.brightness,
                            onChanged: (v) => controller.updateAdjustments(brightness: v, contrast: page.contrast),
                            onChangeEnd: (_) => controller.commitAdjustments(),
                          ),
                          _AdjustSlider(
                            label: 'Contrast',
                            value: page.contrast,
                            onChanged: (v) => controller.updateAdjustments(brightness: page.brightness, contrast: v),
                            onChangeEnd: (_) => controller.commitAdjustments(),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      children: [
                        if (!controller.isFirstPage)
                          Expanded(
                            child: SecondaryButton(label: 'Previous', onPressed: controller.previous),
                          ),
                        if (!controller.isFirstPage) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: controller.isLastPage ? 'Recognize Text' : 'Next Page',
                            icon: controller.isLastPage ? Icons.auto_awesome : Icons.arrow_forward,
                            onPressed: controller.isBusy
                                ? null
                                : (controller.isLastPage ? _proceed : controller.next),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onTap, this.selected = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Theme.of(context).iconTheme.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Expanded(
          child: Slider(
            value: value,
            min: -100,
            max: 100,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}
