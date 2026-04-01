import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:library_of_mysteries/features/library/domain/document.dart';
import 'package:library_of_mysteries/core/database/database_service.dart';
import 'package:library_of_mysteries/features/library/data/document_repository.dart';

void main() {
  late DatabaseService databaseService;
  late DocumentRepository repository;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService(inMemory: true);
    db = await databaseService.database;
    repository = DocumentRepository(db);
    print(await db.rawQuery('PRAGMA foreign_keys'));
  });

  tearDown(() async {
    await db.close();
    await databaseFactory.deleteDatabase(inMemoryDatabasePath);
  });

  test('inserting a document allows it to be retrieved', () async {
    final doc = Document(
      id: 'doc1',
      title: 'The Great Gatsby',
      filePath: '/path/to/gatsby.epub',
      type: 'EPUB',
    );

    await repository.insertDocument(doc);
    final docs = await repository.getAllDocuments();

    expect(docs.length, 1);
    expect(docs.first.id, 'doc1');
    expect(docs.first.title, 'The Great Gatsby');
  });

  test('deleting a document cascades and deletes highlights', () async {
    final doc = Document(
      id: 'doc2',
      title: 'Moby Dick',
      filePath: '/path/to/moby.epub',
      type: 'EPUB',
    );

    await repository.insertDocument(doc);
    
    // Insert a highlight manually for testing
    await db.insert('highlights', {
      'id': 'h1',
      'documentId': 'doc2',
      'text': 'Call me Ishmael.',
      'cfi': 'epubcfi(/2/4/2)',
    });

    // Verify it was inserted
    var highlights = await db.query('highlights');
    expect(highlights.length, 1);

    // Delete the document
    await repository.deleteDocument('doc2');

    // Verify document is gone
    final docs = await repository.getAllDocuments();
    expect(docs.length, 0);

    // Verify highlight is gone (cascading delete)
    highlights = await db.query('highlights');
    expect(highlights.length, 0);
  });
}
