/// A single captured page belonging to a [ScanDocument].
class ScanPage {
  ScanPage({
    required this.id,
    required this.imagePath,
    this.recognizedText = '',
    this.hasRecognitionFailed = false,
  });

  final String id;

  /// Path to the kept, enhanced image on disk. May point to a file that no
  /// longer exists if the user disabled "keep original image".
  final String imagePath;

  final String recognizedText;
  final bool hasRecognitionFailed;

  ScanPage copyWith({
    String? imagePath,
    String? recognizedText,
    bool? hasRecognitionFailed,
  }) {
    return ScanPage(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      recognizedText: recognizedText ?? this.recognizedText,
      hasRecognitionFailed: hasRecognitionFailed ?? this.hasRecognitionFailed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'recognizedText': recognizedText,
        'hasRecognitionFailed': hasRecognitionFailed,
      };

  factory ScanPage.fromJson(Map<dynamic, dynamic> json) => ScanPage(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        recognizedText: json['recognizedText'] as String? ?? '',
        hasRecognitionFailed: json['hasRecognitionFailed'] as bool? ?? false,
      );
}
