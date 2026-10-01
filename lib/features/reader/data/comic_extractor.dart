import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class ComicExtractor {
  final String archivePath;
  late final InputFileStream _inputStream;
  late final Archive _archive;
  late final List<ArchiveFile> _imageFiles;
  final String tempDirPath;
  
  ComicExtractor(this.archivePath, this.tempDirPath);
  
  Future<void> init() async {
    _inputStream = InputFileStream(archivePath);
    _archive = ZipDecoder().decodeBuffer(_inputStream, verify: false);
    
    _imageFiles = _archive.where((file) {
      final name = file.name.toLowerCase();
      return file.isFile && (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.webp'));
    }).toList();
    
    _imageFiles.sort((a, b) => a.name.compareTo(b.name));
  }

  int get pageCount => _imageFiles.length;

  Future<String> getPage(int index) async {
    if (index < 0 || index >= _imageFiles.length) {
      throw RangeError('Page index out of bounds');
    }
    
    final file = _imageFiles[index];
    final outPath = p.join(tempDirPath, 'page_$index\${p.extension(file.name)}');
    
    final outFile = File(outPath);
    if (!await outFile.exists()) {
      final outputStream = OutputFileStream(outPath);
      file.writeContent(outputStream);
      outputStream.close();
    }
    
    return outPath;
  }
  
  void dispose() {
    _inputStream.close();
  }
}
