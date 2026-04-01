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
  static Future<Document> extractMetadata(String filePath, String persistentDir) async {
    final result = await compute(_extractWorker, {
      'filePath': filePath,
      'persistentDir': persistentDir,
    });
    
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

  static ExtractionResult _extractWorker(Map<String, String> args) {
    final filePath = args['filePath']!;
    final persistentDir = args['persistentDir']!;
    final ext = p.extension(filePath).toLowerCase();
    
    if (ext == '.epub') {
      return _extractEpub(filePath, persistentDir);
    } else if (ext == '.cbz') {
      return _extractCbz(filePath, persistentDir);
    }
    
    return ExtractionResult(p.basename(filePath), null);
  }

  static ExtractionResult _extractEpub(String filePath, String persistentDir) {
    final inputStream = InputFileStream(filePath);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    
    String title = p.basenameWithoutExtension(filePath);
    String? coverPath;

    for (final file in archive) {
      if (file.isFile) {
        final name = file.name.toLowerCase();
        if ((name.contains('cover') || name.contains('thumbnail')) && 
            (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'))) {
          final coverFile = File(p.join(persistentDir, 'cover_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}'));
          final content = file.content as List<int>;
          coverFile.writeAsBytesSync(content);
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
    inputStream.close();
    return ExtractionResult(title, coverPath);
  }

  static ExtractionResult _extractCbz(String filePath, String persistentDir) {
    final inputStream = InputFileStream(filePath);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    
    String title = p.basenameWithoutExtension(filePath);
    String? coverPath;
    
    final images = archive.where((file) {
      final name = file.name.toLowerCase();
      return file.isFile && (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'));
    }).toList();
    
    images.sort((a, b) => a.name.compareTo(b.name));
    
    if (images.isNotEmpty) {
      final firstImage = images.first;
      final coverFile = File(p.join(persistentDir, 'cover_${DateTime.now().millisecondsSinceEpoch}_${p.basename(firstImage.name)}'));
      final content = firstImage.content as List<int>;
      coverFile.writeAsBytesSync(content);
      coverPath = coverFile.path;
    }
    
    inputStream.close();
    return ExtractionResult(title, coverPath);
  }
}
