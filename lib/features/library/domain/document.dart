class Document {
  final String id;
  final String title;
  final String filePath;
  final String type;
  final String? coverPath;
  final double progress;

  const Document({
    required this.id,
    required this.title,
    required this.filePath,
    required this.type,
    this.coverPath,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'type': type,
      'cover_path': coverPath,
      'progress': progress,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      type: map['type'] as String,
      coverPath: map['cover_path'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
