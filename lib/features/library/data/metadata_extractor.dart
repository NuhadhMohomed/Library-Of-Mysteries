import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../domain/document.dart';

class ExtractionResult {
  final String title;
  final String? coverPath;

  ExtractionResult(this.title, this.coverPath);
}

class MetadataExtractor {
  static Future<Document> extractMetadata(String filePath) async {
    final result = await compute(_extractWorker, filePath);
    final ext = p.extension(filePath).toLowerCase();
    String type = 'UNKNOWN';
    if (ext == '.epub') type = 'EPUB';
    if (ext == '.cbz' || ext == '.cbr') type = 'COMIC';
    
    return Document(
      id: const Uuid().v4(),
      title: result.title,
      filePath: filePath,
      type: type,
      coverPath: result.coverPath,
    );
  }

  static ExtractionResult _extractWorker(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    
    if (ext == '.epub') {
      return _extractEpub(filePath);
    } else if (ext == '.cbz') {
      return _extractCbz(filePath);
    }
    
    return ExtractionResult(p.basename(filePath), null);
  }

  static ExtractionResult _extractEpub(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    String title = p.basenameWithoutExtension(filePath);
    String? coverPath;

    for (final file in archive) {
      if (file.isFile) {
        final name = file.name.toLowerCase();
        if ((name.contains('cover') || name.contains('thumbnail')) && 
            (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'))) {
          final tempDir = Directory.systemTemp.createTempSync('lib_covers');
          final coverFile = File(p.join(tempDir.path, p.basename(file.name)));
          coverFile.writeAsBytesSync(file.content as List<int>);
          coverPath = coverFile.path;
        }
        
        if (name.endsWith('.opf')) {
          final content = String.fromCharCodes(file.content as List<int>);
          final titleMatch = RegExp(r'<dc:title[^>]*>([^<]+)</dc:title>').firstMatch(content);
          if (titleMatch != null) {
            title = titleMatch.group(1) ?? title;
          }
        }
      }
    }
    
    return ExtractionResult(title, coverPath);
  }

  static ExtractionResult _extractCbz(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    String title = p.basenameWithoutExtension(filePath);
    String? coverPath;
    
    final images = archive.where((file) {
      final name = file.name.toLowerCase();
      return file.isFile && (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'));
    }).toList();
    
    images.sort((a, b) => a.name.compareTo(b.name));
    
    if (images.isNotEmpty) {
      final tempDir = Directory.systemTemp.createTempSync('lib_covers');
      final coverFile = File(p.join(tempDir.path, p.basename(images.first.name)));
      coverFile.writeAsBytesSync(images.first.content as List<int>);
      coverPath = coverFile.path;
    }
    
    return ExtractionResult(title, coverPath);
  }
}
