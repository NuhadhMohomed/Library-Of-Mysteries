import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_of_mysteries/features/library/data/metadata_extractor.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

void main() {
  group('MetadataExtractor', () {
    late Directory tempDir;
    late Directory appDocDir;
    
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('test_files');
      appDocDir = Directory.systemTemp.createTempSync('app_docs');
    });
    
    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (appDocDir.existsSync()) {
        appDocDir.deleteSync(recursive: true);
      }
    });

    test('extracts EPUB metadata correctly', () async {
      // 1. Create a dummy EPUB file (ZIP structure)
      final epubPath = p.join(tempDir.path, 'test_book.epub');
      final encoder = ZipFileEncoder();
      encoder.create(epubPath);
      
      // Add a dummy OPF file
      final opfContent = '<?xml version="1.0"?><package><metadata><dc:title>Test Title</dc:title></metadata></package>';
      final opfFile = File(p.join(tempDir.path, 'content.opf'))..writeAsStringSync(opfContent);
      encoder.addFile(opfFile);
      
      // Add a dummy cover image
      final coverFile = File(p.join(tempDir.path, 'cover.jpg'))..writeAsBytesSync([0, 1, 2, 3]); // Dummy bytes
      encoder.addFile(coverFile);
      
      encoder.close();
      
      // 2. Extract
      final doc = await MetadataExtractor.extractMetadata(epubPath, appDocDir.path);
      
      // 3. Assert
      expect(doc.type, 'EPUB');
      expect(doc.title, 'Test Title');
      expect(doc.filePath, epubPath);
      expect(doc.coverPath, isNotNull);
      
      // Ensure the cover was actually copied into appDocDir, not left in the temp zip location
      expect(doc.coverPath!.startsWith(appDocDir.path), isTrue);
      expect(File(doc.coverPath!).existsSync(), isTrue);
    });

    test('extracts CBZ metadata correctly', () async {
      // 1. Create a dummy CBZ file (ZIP structure)
      final cbzPath = p.join(tempDir.path, 'test_comic.cbz');
      final encoder = ZipFileEncoder();
      encoder.create(cbzPath);
      
      // Add a few dummy pages
      final page1 = File(p.join(tempDir.path, '001.jpg'))..writeAsBytesSync([1, 1]);
      final page2 = File(p.join(tempDir.path, '002.jpg'))..writeAsBytesSync([2, 2]);
      
      encoder.addFile(page1);
      encoder.addFile(page2);
      
      encoder.close();
      
      // 2. Extract
      final doc = await MetadataExtractor.extractMetadata(cbzPath, appDocDir.path);
      
      // 3. Assert
      expect(doc.type, 'COMIC');
      // For CBZ, the title should default to the filename without extension
      expect(doc.title, 'test_comic');
      expect(doc.filePath, cbzPath);
      expect(doc.coverPath, isNotNull);
      
      // Cover should point to the extracted first image
      expect(doc.coverPath!.startsWith(appDocDir.path), isTrue);
      expect(File(doc.coverPath!).existsSync(), isTrue);
    });
  });
}
