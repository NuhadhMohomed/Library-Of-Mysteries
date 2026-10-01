class Document {
  final String id;
  final String title;
  final String filePath;
  final String type;
  final String? coverPath;

  const Document({
    required this.id,
    required this.title,
    required this.filePath,
    required this.type,
    this.coverPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'type': type,
      'coverPath': coverPath,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      type: map['type'] as String,
      coverPath: map['coverPath'] as String?,
    );
  }
}
