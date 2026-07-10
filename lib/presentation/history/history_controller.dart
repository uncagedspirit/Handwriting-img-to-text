import 'package:flutter/material.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/entities/scan_document.dart';

enum HistoryFilter { all, favorites }

/// Business logic for the History screen: listing, searching, favoriting,
/// and deleting (single or batch) past recognitions.
class HistoryController extends ChangeNotifier {
  HistoryController(this._repository) {
    _reload();
  }

  final HistoryRepository _repository;

  List<ScanDocument> _all = [];
  String query = '';
  HistoryFilter filter = HistoryFilter.all;
  bool selectionMode = false;
  final Set<String> selectedIds = {};

  void _reload() {
    _all = _repository.getAll();
    notifyListeners();
  }

  List<ScanDocument> get documents {
    var docs = _all;
    if (filter == HistoryFilter.favorites) {
      docs = docs.where((d) => d.isFavorite).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      docs = docs.where((d) => d.title.toLowerCase().contains(q) || d.displayText.toLowerCase().contains(q)).toList();
    }
    return docs;
  }

  bool get isEmpty => _all.isEmpty;

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setFilter(HistoryFilter value) {
    filter = value;
    notifyListeners();
  }

  void refresh() => _reload();

  Future<void> toggleFavorite(ScanDocument document) async {
    final updated = document.copyWith(isFavorite: !document.isFavorite, updatedAt: DateTime.now());
    await _repository.save(updated);
    _reload();
  }

  Future<void> rename(ScanDocument document, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    final updated = document.copyWith(title: newTitle.trim(), updatedAt: DateTime.now());
    await _repository.save(updated);
    _reload();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _reload();
  }

  void enterSelectionMode(String id) {
    selectionMode = true;
    selectedIds.add(id);
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    if (selectedIds.isEmpty) selectionMode = false;
    notifyListeners();
  }

  void exitSelectionMode() {
    selectionMode = false;
    selectedIds.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(selectedIds);
    exitSelectionMode();
    _reload();
  }
}
