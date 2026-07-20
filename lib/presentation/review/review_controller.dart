import 'package:flutter/material.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/entities/scan_document.dart';

enum ReviewViewMode { text, image, split }

/// Business logic for reviewing and editing a recognized document: text
/// editing (with built-in undo/redo), search & replace, rename, favorite,
/// delete, and save-to-history.
class ReviewController extends ChangeNotifier {
  ReviewController({
    required this.document,
    required HistoryRepository historyRepository,
    required SettingsRepository settingsRepository,
  })  : _history = historyRepository,
        _settings = settingsRepository,
        textController = TextEditingController(text: document.displayText),
        undoController = UndoHistoryController();

  final HistoryRepository _history;
  final SettingsRepository _settings;

  ScanDocument document;
  final TextEditingController textController;
  final UndoHistoryController undoController;
  final FocusNode editorFocusNode = FocusNode();

  ReviewViewMode viewMode = ReviewViewMode.text;
  int imagePageIndex = 0;
  bool isSaved = false;
  bool isDirty = false;

  void initListeners() {
    textController.addListener(() {
      isDirty = textController.text != document.displayText;
      notifyListeners();
    });
  }

  void setViewMode(ReviewViewMode mode) {
    viewMode = mode;
    notifyListeners();
  }

  void setImagePageIndex(int index) {
    imagePageIndex = index;
    notifyListeners();
  }

  bool get hasKeptImages => document.pages.any((p) => p.imagePath.isNotEmpty);

  Future<void> save() async {
    document = document.copyWith(
      editedText: textController.text,
      updatedAt: DateTime.now(),
    );
    await _history.save(document);
    isSaved = true;
    isDirty = false;
    notifyListeners();
  }

  Future<void> autoSaveIfEnabled() async {
    if (_settings.autoSaveHistory) {
      await save();
    }
  }

  Future<void> rename(String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    document = document.copyWith(title: newTitle.trim(), updatedAt: DateTime.now());
    if (isSaved) await _history.save(document);
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    document = document.copyWith(isFavorite: !document.isFavorite, updatedAt: DateTime.now());
    if (isSaved) await _history.save(document);
    notifyListeners();
  }

  Future<void> delete() async {
    if (isSaved) await _history.delete(document.id);
  }

  /// Replaces all case-sensitive occurrences of [search] with [replacement]
  /// in the text field, preserving undo history. Returns the number of
  /// replacements made.
  int replaceAll(String search, String replacement) {
    if (search.isEmpty) return 0;
    final text = textController.text;
    final count = search.allMatches(text).length;
    if (count == 0) return 0;
    final newText = text.replaceAll(search, replacement);
    final selection = textController.selection;
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.baseOffset.clamp(0, newText.length)),
    );
    return count;
  }

  void selectAll() {
    // The field must be focused first or the selection is never rendered.
    editorFocusNode.requestFocus();
    textController.selection = TextSelection(baseOffset: 0, extentOffset: textController.text.length);
  }

  @override
  void dispose() {
    textController.dispose();
    undoController.dispose();
    editorFocusNode.dispose();
    super.dispose();
  }
}
