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

  final FileStorage _storage;
  final DocxWriter _docxWriter = const DocxWriter();

  Future<File> exportToFile(String text, String fileName, ExportFormat format) async {
    final dir = await _storage.exportsDir;
    final path = '${dir.path}/$fileName.${format.extension}';
    final file = File(path);

    switch (format) {
      case ExportFormat.txt:
        await file.writeAsString(text, flush: true);
      case ExportFormat.pdf:
        await file.writeAsBytes(await _buildPdf(text), flush: true);
      case ExportFormat.docx:
        await file.writeAsBytes(_docxWriter.build(text, title: fileName), flush: true);
    }

    final downloads = await _storage.downloadsDir;
    if (downloads != null) {
      try {
        await file.copy('${downloads.path}/$fileName.${format.extension}');
      } catch (_) {
        // Downloads folder may be inaccessible on some devices/scoped-storage
        // configurations; the app-private copy above always succeeds.
      }
    }

    return file;
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
