/// On-device recognition scripts supported by the bundled ML Kit models.
/// Each script downloads/uses its own small offline model.
enum RecognitionLanguage {
  latin('latin', 'Latin', 'English & other Latin-script languages'),
  chinese('chinese', 'Chinese', 'Simplified & traditional Chinese'),
  devanagari('devanagari', 'Devanagari', 'Hindi, Marathi & related scripts'),
  japanese('japanese', 'Japanese', 'Japanese kanji, hiragana & katakana'),
  korean('korean', 'Korean', 'Korean hangul');

  const RecognitionLanguage(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static RecognitionLanguage fromCode(String code) {
    return RecognitionLanguage.values.firstWhere(
      (e) => e.code == code,
      orElse: () => RecognitionLanguage.latin,
    );
  }
}

enum ExportFormat {
  txt('txt', 'Plain Text (.txt)'),
  pdf('pdf', 'PDF Document (.pdf)'),
  docx('docx', 'Word Document (.docx)');

  const ExportFormat(this.extension, this.label);

  final String extension;
  final String label;

  static ExportFormat fromExtension(String extension) {
    return ExportFormat.values.firstWhere(
      (e) => e.extension == extension,
      orElse: () => ExportFormat.txt,
    );
  }
}

enum ThemeModePreference {
  system('system', 'System default'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  const ThemeModePreference(this.code, this.label);

  final String code;
  final String label;

  static ThemeModePreference fromCode(String code) {
    return ThemeModePreference.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ThemeModePreference.system,
    );
  }
}

enum BatchMode {
  merge('Merge into one document'),
  separate('Keep as separate documents');

  const BatchMode(this.label);

  final String label;
}
