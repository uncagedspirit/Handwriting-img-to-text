import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Result of a find & replace request: the terms the user entered.
class FindReplaceRequest {
  const FindReplaceRequest(this.search, this.replacement);

  final String search;
  final String replacement;
}

/// Collects find/replace terms. Stateful so both text controllers are
/// disposed with the sheet rather than leaking on every open.
Future<FindReplaceRequest?> showFindReplaceSheet(BuildContext context) {
  return showModalBottomSheet<FindReplaceRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _FindReplaceSheet(),
  );
}

class _FindReplaceSheet extends StatefulWidget {
  const _FindReplaceSheet();

  @override
  State<_FindReplaceSheet> createState() => _FindReplaceSheetState();
}

class _FindReplaceSheetState extends State<_FindReplaceSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Keeps the Replace All button correctly enabled/disabled as they type.
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_searchController.text.isEmpty) return;
    Navigator.of(context).pop(
      FindReplaceRequest(_searchController.text, _replaceController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find & Replace', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Find'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _replaceController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: 'Replace with'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              // Replacing an empty search term would be a no-op, so the
              // button stays disabled until there is something to find.
              onPressed: _searchController.text.isEmpty ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Replace All'),
            ),
          ),
        ],
      ),
    );
  }
}
