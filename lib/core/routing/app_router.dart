import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/presentation/library_screen.dart';
import '../../features/reader/presentation/book_reader_screen.dart';
import '../../features/reader/presentation/comic_reader_screen.dart';
import '../../features/library/domain/document.dart';

// Placeholder screens for now
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

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
          return PlaceholderScreen(title: 'Reader: $id');
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
    ],
  );
});
