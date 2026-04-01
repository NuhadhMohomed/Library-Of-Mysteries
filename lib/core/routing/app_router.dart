import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/presentation/library_screen.dart';
import '../../features/reader/presentation/book_reader_screen.dart';
import '../../features/reader/presentation/comic_reader_screen.dart';
import '../../features/library/domain/document.dart';

// Removed PlaceholderScreen as part of ponytail audit YAGNI cleanup.

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/reader/:id',
        builder: (context, state) {
          final String id = state.pathParameters['id'] ?? '';
          final doc = state.extra as Document?;
          if (doc != null) {
            if (doc.type == 'EPUB') {
              return BookReaderScreen(document: doc);
            } else if (doc.type == 'COMIC') {
              return ComicReaderScreen(document: doc);
            }
          }
          return Scaffold(appBar: AppBar(title: Text('Reader: $id')));
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(appBar: AppBar(title: const Text('Settings'))),
      ),
    ],
  );
});
