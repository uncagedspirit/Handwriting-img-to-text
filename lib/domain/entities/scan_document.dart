import 'scan_page.dart';

/// A recognition session made of one or more pages, persisted to history.
class ScanDocument {
  ScanDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    this.isFavorite = false,
    this.languageCode = 'en',
    this.editedText,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScanPage> pages;
  final bool isFavorite;
  final String languageCode;

  /// User-edited version of the recognized text, if the user has made
  /// changes since recognition. When null, [displayText] falls back to the
  /// raw per-page recognition output.
  final String? editedText;

  /// Combined text of every page, separated by a blank line so paragraph
  /// structure between pages remains visually distinct.
  String get combinedText => pages.map((p) => p.recognizedText).join('\n\n');

  /// The text that should be shown/edited/exported: the user's edits if any,
  /// otherwise the raw recognition output.
  String get displayText => editedText ?? combinedText;

  bool get hasAnyFailure => pages.any((p) => p.hasRecognitionFailed);

  ScanDocument copyWith({
    String? title,
    DateTime? updatedAt,
    List<ScanPage>? pages,
    bool? isFavorite,
    String? languageCode,
    String? editedText,
  }) {
    return ScanDocument(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      isFavorite: isFavorite ?? this.isFavorite,
      languageCode: languageCode ?? this.languageCode,
      editedText: editedText ?? this.editedText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
        'isFavorite': isFavorite,
        'languageCode': languageCode,
        'editedText': editedText,
      };

  factory ScanDocument.fromJson(Map<dynamic, dynamic> json) => ScanDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        pages: (json['pages'] as List)
            .map((p) => ScanPage.fromJson(Map<dynamic, dynamic>.from(p as Map)))
            .toList(),
        isFavorite: json['isFavorite'] as bool? ?? false,
        languageCode: json['languageCode'] as String? ?? 'en',
        editedText: json['editedText'] as String?,
      );
}
