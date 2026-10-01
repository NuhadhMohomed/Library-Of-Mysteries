import 'package:sqflite/sqflite.dart';
import '../domain/document.dart';

class DocumentRepository {
  final Database db;
  DocumentRepository(this.db);

  Future<void> insertDocument(Document document) async {
    await db.insert(
      'documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Document>> getAllDocuments() async {
    final List<Map<String, dynamic>> maps = await db.query('documents');
    return List.generate(maps.length, (i) {
      return Document.fromMap(maps[i]);
    });
  }

  Future<void> deleteDocument(String id) async {
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
