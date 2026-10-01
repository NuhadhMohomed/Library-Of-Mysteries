import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../library/domain/document.dart';
import '../data/comic_extractor.dart';

class ComicReaderScreen extends ConsumerStatefulWidget {
  final Document document;

  const ComicReaderScreen({super.key, required this.document});

  @override
  ConsumerState<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends ConsumerState<ComicReaderScreen> {
  ComicExtractor? _extractor;
  final PageController _pageController = PageController();
  final Map<int, String> _pageCache = {};
  bool _isLoading = true;
  bool _showUi = true;

  @override
  void initState() {
    super.initState();
    _initExtractor();
  }

  Future<void> _initExtractor() async {
    final tempDir = await getTemporaryDirectory();
    final comicDir = Directory('${tempDir.path}/${widget.document.id}');
    if (!await comicDir.exists()) {
      await comicDir.create(recursive: true);
    }
    
    _extractor = ComicExtractor(widget.document.filePath, comicDir.path);
    await _extractor!.init();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _preloadPage(0);
      _preloadPage(1);
    }
  }

  Future<void> _preloadPage(int index) async {
    if (_extractor == null || index < 0 || index >= _extractor!.pageCount) return;
    if (_pageCache.containsKey(index)) return;
    
    final path = await _extractor!.getPage(index);
    if (mounted) {
      setState(() {
        _pageCache[index] = path;
      });
    }
  }

  @override
  void dispose() {
    _extractor?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _extractor == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUi
          ? AppBar(
              title: Text(widget.document.title),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showUi = !_showUi;
          });
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _extractor!.pageCount,
          onPageChanged: (index) {
            _preloadPage(index);
            _preloadPage(index + 1);
            _preloadPage(index + 2);
          },
          itemBuilder: (context, index) {
            final pagePath = _pageCache[index];
            if (pagePath == null) {
              _preloadPage(index);
              return const Center(child: CircularProgressIndicator());
            }
            
            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(
                File(pagePath),
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
