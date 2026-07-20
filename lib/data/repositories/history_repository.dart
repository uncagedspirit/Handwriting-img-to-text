import 'dart:io';
import 'package:hive/hive.dart';
import '../../domain/entities/scan_document.dart';

/// Persists recognition history locally using Hive. Documents are stored as
/// plain maps, so no code generation step is required.
class HistoryRepository {
  HistoryRepository(this._box);

  final Box<Map> _box;

  List<ScanDocument> getAll() {
    final docs = _box.values.map((raw) => ScanDocument.fromJson(raw)).toList();
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  ScanDocument? getById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return ScanDocument.fromJson(raw);
  }

  Future<void> save(ScanDocument document) => _box.put(document.id, document.toJson());

  Future<void> delete(String id) async {
    await _deletePageImages(id);
    await _box.delete(id);
  }

  Future<void> deleteMany(Iterable<String> ids) async {
    for (final id in ids) {
      await _deletePageImages(id);
    }
    await _box.deleteAll(ids);
  }

  Future<void> clear() async {
    for (final id in _box.keys) {
      await _deletePageImages(id as String);
    }
    await _box.clear();
  }

  /// A document's kept page images live only for that document; removing
  /// the entry without them would leak storage that the user can never
  /// reclaim from inside the app.
  Future<void> _deletePageImages(String id) async {
    final document = getById(id);
    if (document == null) return;
    for (final page in document.pages) {
      if (page.imagePath.isEmpty) continue;
      final file = File(page.imagePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // A locked/missing file shouldn't block deleting the document.
        }
      }
    }
  }
}
