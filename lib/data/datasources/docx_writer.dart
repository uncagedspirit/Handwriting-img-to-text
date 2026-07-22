import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../../core/constants/app_config.dart';

/// Builds a minimal, valid `.docx` (Office Open XML) file from plain text,
/// without depending on a heavyweight document-authoring package. Each line
/// of input becomes its own paragraph, so paragraph structure from
/// recognition is preserved.
class DocxWriter {
  const DocxWriter();

  Uint8List build(String text, {String title = 'Document'}) {
    final archive = Archive();

    void addXml(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addXml('[Content_Types].xml', _contentTypesXml);
    addXml('_rels/.rels', _relsXml);
    addXml('docProps/core.xml', _coreXml(title));
    addXml('word/document.xml', _documentXml(text));

    final zipped = ZipEncoder().encode(archive) ?? <int>[];
    return Uint8List.fromList(zipped);
  }

  static const _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
</Types>''';

  static const _relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
</Relationships>''';

  String _coreXml(String title) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/">
<dc:title>${_escape(title)}</dc:title>
<dc:creator>${_escape(AppConfig.appName)}</dc:creator>
</cp:coreProperties>''';

  String _documentXml(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write(
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>',
    );
    for (final line in lines) {
      if (line.trim().isEmpty) {
        buffer.write('<w:p/>');
      } else {
        buffer.write('<w:p><w:r><w:t xml:space="preserve">${_escape(line)}</w:t></w:r></w:p>');
      }
    }
    buffer.write('<w:sectPr/></w:body></w:document>');
    return buffer.toString();
  }

  String _escape(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
