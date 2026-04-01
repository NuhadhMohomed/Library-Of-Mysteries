import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/metadata_extractor.dart';
import 'package:library_of_mysteries/features/library/application/library_provider.dart';

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref);
});

class ImportService {
  final Ref ref;

  ImportService(this.ref);

  Future<void> importFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'cbz', 'cbr', 'docx'],
    );

    if (files.isNotEmpty) {
      for (final file in files) {
        if (file.path != null) {
          try {
            final document = await MetadataExtractor.extractMetadata(file.path!);
            final libraryNotifier = ref.read(libraryProvider.notifier);
            await libraryNotifier.addDocument(document);
          } catch (e) {
            debugPrint('Failed to import ${file.path}: $e');
          }
        }
      }
    }
  }
}
