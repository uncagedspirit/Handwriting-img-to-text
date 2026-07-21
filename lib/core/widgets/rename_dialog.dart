import 'package:flutter/material.dart';

/// Prompts for a new document title. Returns the trimmed title, or null if
/// the user cancelled or left it empty.
///
/// Lives in its own stateful widget so the [TextEditingController] is
/// disposed with the dialog — creating one inline in a screen method leaks
/// it every time the dialog is opened.
Future<String?> showRenameDialog(BuildContext context, String currentTitle) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(initialTitle: currentTitle),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
    // Pre-select so typing replaces the old title, which is the common case.
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.initialTitle.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Document'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Document name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
