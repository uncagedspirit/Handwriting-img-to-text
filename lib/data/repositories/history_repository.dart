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

  Future<void> delete(String id) => _box.delete(id);

  Future<void> deleteMany(Iterable<String> ids) => _box.deleteAll(ids);

  Future<void> clear() => _box.clear();
}
