# Library of Mysteries — Flutter Android Reader App
## Implementation Plan

> **Status**: ✅ Architecture approved. Phase 1 in progress.
> **Stack**: Flutter (Android Only) · Riverpod · sqflite · Material 3 · epub_view · archive · go_router

---

# Part 1 — Product Requirements Document (PRD)

## 1.1 Vision & Scope
**Library of Mysteries** is a fully offline, Android-only reader application that unifies document reading (EPUB, DOCX) and comic reading (CBZ, CBR) into a single, cohesive experience. It borrows the deep reading customization of *Moon+ Reader*.
All data stays on-device. No network calls, no accounts, no cloud sync.

## 1.2 User Personas
| Persona | Primary Use Case |
|---|---|
| **The Novel Reader** | Imports EPUB/DOCX webnovels; uses dark mode, custom fonts, progress tracking |
| **The Comic Fan** | Imports CBZ/CBR manga/comics; uses horizontal paging, page curls |

## 1.3 Feature Requirements

### FR-1: Library Management
- **Scan & Import**: Scan specific device folders (like Downloads) and allow users to manually import files one-by-one into the app's internal library.
- **Database**: Build a local library with metadata and covers using `sqflite` (matching Moon+ Reader's native SQLite approach).
- **Tabs**: Separate views for Books and Comics.
- **First-Time User Experience (FTUE)**: Open straight to an empty Library screen with a clear "Scan Device" / "Import" button.

### FR-2: Book Reader Features (EPUB, DOCX)
- **Parsing**: Use established third-party Flutter packages (e.g., `epub_view` for EPUB).
- **Rendering**: Highly complex reading view from day 1.
- **Customization**: Deep customization including themes (Light, Sepia, Dark, AMOLED), margins, line spacing, and font sizes.
- **Animations**: Page-curl animations during page turns.

### FR-3: Comic Reader Features (CBZ, CBR)
- **Parsing**: Use the `archive` package to extract and read compressed image files.
- **Reading Modes**: Horizontal paging with page-curl animations.

### FR-4: Global UX
- **State Management**: `Riverpod` for robust and scalable state handling.
- **UI Design**: `Material 3` for a modern Android-native feel.

---

# Part 2 — Technical Architecture Document (TAD)

## 2.1 Project Initialization
- **Package Name**: `com.libraryofmysteries.app`

## 2.2 Directory Structure (Feature-First)
The app will use a feature-first architecture to keep related code together.

```text
lib/
├── core/                   # Shared utilities, theme, database setup
│   ├── database/
│   ├── theme/
│   └── utils/
├── features/
│   ├── library/            # Library scanning, grid view, metadata
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   ├── reader/             # The core reading experience
│   │   ├── presentation/   # Page-curl UI, bottom sheets
│   │   ├── application/
│   │   └── data/           # Parsers (epub, docx, cbz)
│   └── settings/           # Customization options
└── main.dart
```

## 2.3 State Management & Routing
- **State/DI**: **Riverpod** will be used across the app (e.g., `libraryProvider`, `readerPreferencesProvider`).
- **Routing**: **go_router** for modern, declarative routing between the Library, Reader, and Settings screens.

## 2.4 Database Schema (sqflite)
We will use a relational schema via `sqflite` to ensure fast queries and data integrity.

**Table: `documents`**
- `id` (TEXT PRIMARY KEY)
- `title` (TEXT)
- `author` (TEXT)
- `file_path` (TEXT)
- `file_type` (TEXT) - epub, docx, cbz, cbr
- `cover_path` (TEXT)
- `progress` (REAL)
- `last_read` (INTEGER)

## 2.5 Performance & Memory Management
- **Background Tasks (Isolates)**: When scanning folders or parsing metadata, use Flutter Isolates (via `compute`) to offload work so the main UI thread remains completely responsive.
- **Comic Memory Management**: Use **Windowed Extraction & Lazy Rendering** to avoid Out of Memory (OOM) crashes. Extract only a few pages at a time into a cache directory and load them as the user scrolls, rather than extracting the entire archive into memory at once.

## 2.6 Typography & Accessibility
- **Base Typography**: Adhere to strict mobile design rules (16px base body font) with minimum AA contrast for the app shell.
- **Reader Scaling**: User-controlled font scaling and customization (margins, line spacing) is restricted exclusively to the Reader view to prevent breaking the Library Grid layout.

## 2.7 Testing Strategy (TDD)
- **Scope**: Test-Driven Development (TDD) will be used strictly for the core logic layer (`data/` parsers, isolate extractors, database queries, and `application/` state management).
- **UI Tests**: Kept to a minimum for critical paths (e.g., Library Import) to maintain rapid UI iteration speed.
---

# Part 3 — Phased Implementation Roadmap

## Phase 1: Foundation & Library
- Initialize Flutter project (`com.libraryofmysteries.app`).
- Set up Riverpod, go_router, Material 3, and sqflite.
- Implement folder scanning and manual file import (using isolates).
- Build the Library Grid UI (FTUE and populated state).

## Phase 2: Core Parsing Engine
- Integrate `epub_view` and `archive` packages.
- Extract metadata (covers, title, author) during import in the background.
- Establish the data bridge between the raw files and the UI.

## Phase 3: The Reading Experience (Day 1 Complexity)
- Implement the page-curl animation.
- Build the highly customizable reader view (margins, line spacing, fonts).
- Implement themes (Day/Night modes).
- Save and resume reading progress.
- Implement windowed extraction for large comic archives.

## Phase 4: Polish & Optimization
- Add transitions, micro-animations, and error handling.
- Final UI tweaks to match a premium reading experience.
