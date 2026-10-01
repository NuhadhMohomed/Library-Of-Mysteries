# ADR-0001: Adopt Flutter and sqflite for Mobile Reader

## Status
Accepted

## Context
We need to build a fully offline Android mobile reader application supporting books (EPUB, DOCX) and comics (CBZ, CBR). A previous implementation plan targeted React Native. However, the app requires deep UI customization, complex gestures, and high-performance page-curl animations which are difficult to optimize across the React Native bridge, especially when parsing large files.

## Decision
We will pivot the project to **Flutter** targeting Android exclusively for v1, using:
- **Riverpod** for state management and dependency injection.
- **sqflite** for local library metadata and progress persistence (mirroring the native SQLite approach).
- **go_router** for declarative routing.
- **Flutter Isolates** (via `compute`) to handle heavy parsing off the main thread.

## Rationale
Flutter provides a high-performance rendering engine that is perfectly suited for building a highly customizable reader view with complex animations from day 1. Using Isolates ensures that extracting metadata from large CBZ/CBR archives won't drop frames in the UI.

## Consequences
### Positive
- Smooth page-curl animations without bridge overhead.
- Excellent third-party packages for file parsing (`epub_view`, `archive`).
- Strong type safety with Dart.
### Negative
- Requires discarding the existing React Native implementation plan.
- Flutter's tree-shaking and memory management must be carefully monitored when dealing with hundreds of high-res comic images (mitigated via Windowed Extraction).
