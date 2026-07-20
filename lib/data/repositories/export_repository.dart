import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../core/utils/file_storage.dart';
import '../../domain/entities/app_enums.dart';
import '../datasources/docx_writer.dart';

/// Handles turning recognized text into TXT/PDF/DOCX files, plus clipboard
/// and share actions. All output stays on-device.
class ExportRepository {
  ExportRepository(this._storage);

  static const _downloadsChannel = MethodChannel('handwriting_to_text/downloads');

  final FileStorage _storage;
  final DocxWriter _docxWriter = const DocxWriter();

  Future<File> exportToFile(
    String text,
    String fileName,
    ExportFormat format, {
    bool copyToDownloads = true,
  }) async {
    final dir = await _storage.exportsDir;
    final safeName = _sanitizeFileName(fileName);
    final file = await _uniqueFile(dir, safeName, format.extension);

    switch (format) {
      case ExportFormat.txt:
        await file.writeAsString(text, flush: true);
      case ExportFormat.pdf:
        await file.writeAsBytes(await _buildPdf(text), flush: true);
      case ExportFormat.docx:
        await file.writeAsBytes(_docxWriter.build(text, title: fileName), flush: true);
    }

    if (copyToDownloads) {
      await _copyToDownloads(file, format);
    }

    return file;
  }

  /// Document titles are user-editable free text; strip characters that are
  /// illegal in filenames so a title like "Math: Ch 5?" can't make every
  /// export fail.
  String _sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? 'Document' : cleaned;
  }

  /// Appends " (2)", " (3)", ... when a file with the same name already
  /// exists so a re-export can't silently overwrite an earlier one.
  Future<File> _uniqueFile(Directory dir, String baseName, String extension) async {
    var candidate = File('${dir.path}/$baseName.$extension');
    var counter = 2;
    while (await candidate.exists()) {
      candidate = File('${dir.path}/$baseName ($counter).$extension');
      counter++;
    }
    return candidate;
  }

  /// Publishes a copy into the system Downloads collection via MediaStore
  /// on Android 10+, which needs no storage permission. Older Android
  /// versions (and failures) are non-fatal: the app-private copy always
  /// exists and Share remains available.
  Future<void> _copyToDownloads(File file, ExportFormat format) async {
    if (!Platform.isAndroid) return;
    try {
      final name = file.uri.pathSegments.last;
      await _downloadsChannel.invokeMethod<bool>('saveToDownloads', {
        'name': name,
        'mimeType': _mimeTypeFor(format),
        'bytes': await file.readAsBytes(),
      });
    } catch (_) {
      // Best-effort: never let the Downloads copy break the export itself.
    }
  }

  String _mimeTypeFor(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt:
        return 'text/plain';
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
  }

  Future<Uint8List> _buildPdf(String text) async {
    final doc = pw.Document();
    const pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
    );
    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) => [
          pw.Text(text, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> copyToClipboard(String text) => Clipboard.setData(ClipboardData(text: text));

  Future<void> shareText(String text, {String? subject}) {
    return Share.share(text, subject: subject);
  }

  Future<void> shareFile(File file) {
    return Share.shareXFiles([XFile(file.path)]);
  }
}
