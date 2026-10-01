import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_view/epub_view.dart';
import '../../library/domain/document.dart';
import '../application/reader_settings_provider.dart';
import 'widgets/reader_settings_sheet.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final Document document;

  const BookReaderScreen({super.key, required this.document});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      document: EpubDocument.openFile(File(widget.document.filePath)),
    );
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: settings.margin),
        child: EpubView(
          controller: _epubController,
          builders: EpubViewBuilders<DefaultBuilderOptions>(
            options: DefaultBuilderOptions(
              textStyle: TextStyle(
                fontSize: settings.fontSize,
                height: settings.lineSpacing,
              ),
            ),
            chapterDividerBuilder: (_) => const Divider(),
          ),
        ),
      ),
    );
  }
}
