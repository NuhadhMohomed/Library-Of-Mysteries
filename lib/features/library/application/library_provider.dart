import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/document.dart';
import '../data/document_repository.dart';
import '../../../core/database/database_service.dart';

// Provides the DatabaseService instance
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Provides the DocumentRepository instance
final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = await dbService.database;
  return DocumentRepository(db);
});

// The Library Provider exposing the list of documents
final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<Document>>(() {
  return LibraryNotifier();
});

class LibraryNotifier extends AsyncNotifier<List<Document>> {
  @override
  Future<List<Document>> build() async {
    return _fetchDocuments();
  }

  Future<List<Document>> _fetchDocuments() async {
    final repository = await ref.read(documentRepositoryProvider.future);
    return repository.getAllDocuments();
  }

  Future<void> addDocument(Document document) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(documentRepositoryProvider.future);
      await repository.insertDocument(document);
      return _fetchDocuments();
    });
  }

  Future<void> removeDocument(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(documentRepositoryProvider.future);
      await repository.deleteDocument(id);
      return _fetchDocuments();
    });
  }

  Future<void> updateProgress(String id, double progress) async {
    final repository = await ref.read(documentRepositoryProvider.future);
    await repository.updateProgress(id, progress);
    
    state = state.whenData((documents) {
      return documents.map((doc) {
        if (doc.id == id) {
          return Document(
            id: doc.id,
            title: doc.title,
            filePath: doc.filePath,
            type: doc.type,
            coverPath: doc.coverPath,
            progress: progress,
          );
        }
        return doc;
      }).toList();
    });
  }
}
