# Library of Mysteries — Android Reader App
## 5-Part Implementation Plan

> **Status**: ✅ Architecture approved. Phase 1 in progress.
> **Stack**: React Native + Expo (Custom Dev Client) · NativeWind v4 · react-native-reusables · Expo Router · expo-sqlite · expo-file-system · Zustand

---

# Part 1 — Product Requirements Document (PRD)

## 1.1 Vision & Scope

**Library of Mysteries** is a fully offline, Android-only reader application that unifies document reading (EPUB, DOCX, PDF) and comic reading (CBZ, CBR) into a single, cohesive experience. It borrows the deep reading customization of *Moon+ Reader* and the clean, content-first library UI of *Webnovel*.

All data stays on-device. No network calls, no accounts, no cloud sync.

---

## 1.2 User Personas

| Persona | Primary Use Case |
|---|---|
| **The Novel Reader** | Imports EPUB/DOCX webnovels; uses dark mode, custom fonts, progress tracking |
| **The PDF Scholar** | Imports academic PDFs; uses highlights and notes |
| **The Comic Fan** | Imports CBZ/CBR manga/comics; uses horizontal paging and vertical scroll |

---

## 1.3 Feature Requirements

### FR-1: Split Library (Top Tabs)
- Library screen has two strictly separated top tabs: **Books** and **Comics**.
- Books tab: displays EPUB, DOCX, PDF documents.
- Comics tab: displays CBZ, CBR archives.
- Each tab shows a grid of cover thumbnails + title + last-read progress bar.
- Both tabs share the same FAB import button (bottom-right).

### FR-2: Smart File Import Pipeline
- Floating Action Button (FAB) triggers the Android native file picker via `expo-document-picker`.
- **Auto-categorization logic** (pure extension-based, no MIME guessing):
  - `.epub`, `.pdf`, `.docx` → `media_type = 'book'`
  - `.cbz`, `.cbr` → `media_type = 'comic'`
  - All other extensions → reject with a toast notification.
- Imported file is **first copied to `FileSystem.cacheDirectory`** for zero-latency opening.
- The reader opens immediately from the cache path.

### FR-3: Temporary vs. Permanent Library Model
| State | Storage Location | SQLite Record | Behavior |
|---|---|---|---|
| **Temporary** | `cacheDirectory/imports/` | `is_temporary = 1` | Opens fine; shown with a "Not Saved" badge |
| **Permanent** | `documentDirectory/library/` | `is_temporary = 0` | Persists across cache clears |

- An **"Add to Library"** action (in reader toolbar or via long-press card) triggers the promotion flow:
  1. Copy file from `cacheDirectory` → `documentDirectory/library/{uuid}.{ext}`
  2. Update the SQLite record: `is_temporary = 0`, `file_uri` updated.
  3. Delete the cache copy.
- Permanent files are organized in subdirectories: `library/books/` and `library/comics/`.

### FR-4: Book Reader Features
- **Rendering engines** (selected by `file_type`):
  - `.epub` → `epub.js` via `react-native-webview`
  - `.docx` → `mammoth.js` via `react-native-webview`
  - `.pdf` → `react-native-pdf`
- **Theme System**: Light, Sepia, Dark, AMOLED Black.
- **Typography**: Font family selector (serif/sans-serif/monospace), font size slider (12–24px), line height control.
- **Progress**: Saved as `progress_data` JSON (`{ cfi: string, page: number, percentage: number }`).
- **Highlights**: Color-coded text selection with optional note. Persisted via the `highlights` table.
- **Chapter Navigation**: TOC drawer slide-in from left.

### FR-5: Comic Reader Features
- **Extraction**: CBZ (ZIP) via `react-native-zip-archive`. CBR support via a bundled `unrar` native bridge.
- **Rendering**: `@shopify/flash-list` renders extracted image URIs.
- **Reading Modes**:
  - **Horizontal Paging** (default): swipe left/right, one page at a time.
  - **Vertical Continuous Scroll**: long-strip manga mode.
- **Progress**: Saved as `progress_data` JSON (`{ currentPage: number, totalPages: number }`).
- **Page indicator overlay**: "12 / 248" tap-to-dismiss.
- **Double-tap to zoom** on individual pages.

### FR-6: Global UX
- Bottom tab navigation: **Library**, **Recents**, **Settings**.
- **Recents** tab: flat list of the 20 most recently opened documents (any type).
- **Settings**: Default theme, default comic reading mode, clear cache action, app version.
- Fully offline — no network permissions declared in `AndroidManifest.xml`.

---

## 1.4 Out of Scope (v1)
- Cloud sync, user accounts, sharing.
- Annotations export (PDF/CSV).
- TTS (Text-to-Speech).
- MOBI / AZW3 format support.
- iOS support.

---
---

# Part 2 — Technical Architecture Document (TAD)

## 2.1 High-Level System Diagram

```
┌─────────────────────────────────────────────────────┐
│                  Expo Router (RN)                    │
│  ┌──────────────┐  ┌───────────┐  ┌──────────────┐  │
│  │  Library UI  │  │  Recents  │  │   Settings   │  │
│  │  (Top Tabs)  │  │           │  │              │  │
│  └──────┬───────┘  └───────────┘  └──────────────┘  │
│         │ navigate /reader/[id]                      │
│  ┌──────▼───────────────────────────────────────┐    │
│  │              ReaderScreen (Dynamic Route)     │    │
│  │  ┌─────────────────┐  ┌──────────────────┐   │    │
│  │  │   BookEngine    │  │   ComicEngine    │   │    │
│  │  │  (WebView/PDF)  │  │  (FlashList)     │   │    │
│  │  └─────────────────┘  └──────────────────┘   │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌────────────────┐        ┌──────────────────────┐
│  expo-sqlite   │        │   expo-file-system   │
│  (documents,   │        │  cacheDir / docDir   │
│   highlights)  │        └──────────────────────┘
└────────────────┘
```

---

## 2.2 Android File Intercept Routing

### 2.2.1 Entry Points
There are **two ways** a file enters the app:

1. **In-App Import (FAB)**: User taps FAB → `expo-document-picker` → returns a content URI (`content://`).
2. **Android Intent Intercept**: User opens a supported file from Files app or a download manager → Android forwards the intent to our app.

### 2.2.2 Intent Filter Configuration (`app.json` → `AndroidManifest.xml`)
```
Intent Filter:
  action: android.intent.action.VIEW
  category: android.intent.category.DEFAULT
  category: android.intent.category.BROWSABLE
  mimeTypes:
    - application/epub+zip
    - application/pdf
    - application/vnd.openxmlformats-officedocument.wordprocessingml.document
    - application/x-cbz  (+ application/zip for .cbz fallback)
    - application/x-cbr  (+ application/x-rar-compressed for .cbr fallback)
```

### 2.2.3 Import Service (`src/services/ImportService.ts`)
This is the **single point of truth** for all file ingestion:

```
ImportService.ingest(sourceUri: string):
  1. Resolve extension from URI (strip query params, decode %20, etc.)
  2. Determine media_type & file_type from extension map
  3. Generate a UUID filename: {uuid}.{ext}
  4. Copy to cacheDirectory/imports/{uuid}.{ext} via FileSystem.copyAsync
  5. Extract cover thumbnail:
     - EPUB: unzip cover image from ZIP structure
     - PDF: render page 0 to a bitmap (react-native-pdf utility)
     - DOCX: use first embedded image or generate text-based placeholder
     - CBZ: unzip first image alphabetically
     - CBR: use unrar bridge to extract first image
  6. Write thumbnail to cacheDirectory/covers/{uuid}.jpg
  7. INSERT into documents table (is_temporary = 1)
  8. Return document record → navigate to /reader/{id}
```

### 2.2.4 `media_type` Categorization Map
| Extension | `media_type` | `file_type` | Engine |
|---|---|---|---|
| `.epub` | `book` | `epub` | WebView + epub.js |
| `.docx` | `book` | `docx` | WebView + mammoth.js |
| `.pdf` | `book` | `pdf` | react-native-pdf |
| `.cbz` | `comic` | `cbz` | FlashList |
| `.cbr` | `comic` | `cbr` | FlashList |

---

## 2.3 State Management Strategy

**Zustand** for global/cross-component state. Custom hooks for SQLite access.

| Layer | Tool | Scope |
|---|---|---|
| **DB / Server State** | Custom hooks (`useDocuments`, `useHighlights`) wrapping `expo-sqlite` | Per-screen |
| **Reader UI State** | Zustand `useReaderStore` | Reader screen + Settings Sheet |
| **Import Pipeline State** | Zustand `useImportStore` | FAB → Library grid |
| **App Preferences** | Zustand `usePrefsStore` + `persist` middleware (AsyncStorage) | Global, persistent |
| **Navigation State** | Expo Router (URL params) | Implicit |

**Store breakdown:**
```
useReaderStore    → theme, fontSize, fontFamily, comicMode, overlayVisible
useImportStore    → importQueue[], currentImport, progress
usePrefsStore     → defaultTheme, defaultComicMode (persisted to AsyncStorage)
```
Components never call SQLite directly — only through the custom hook layer.

---

## 2.4 Comic Engine: Memory Management Strategy

**The Problem**: A single CBZ/CBR comic can contain 200–400 high-resolution images (2–5 MB each uncompressed). Loading all of them into memory simultaneously on a mid-range Android device would cause an OOM crash.

**The Solution: Windowed Extraction + Lazy Rendering**

```
Phase 1 — Initial Open:
  Extract ONLY pages [0, 1, 2] to cacheDirectory/extracted/{uuid}/
  Navigate to reader with page 0 immediately.

Phase 2 — Predictive Prefetch (background task):
  As user reads page N, extract pages [N+3, N+4, N+5] in background.
  Delete pages [N-5, N-4, N-3] that are far behind the viewport.

Phase 3 — FlashList Virtualization:
  FlashList only renders the 3 pages visible in the viewport.
  Images outside the render window are unmounted from the RN tree.
  Use `recyclingKey` prop to prevent stale image flicker.

Phase 4 — Cleanup on Reader Unmount:
  Save progress to SQLite.
  Delete all extracted images from cacheDirectory/extracted/{uuid}/.
  Only permanent files (documentDirectory) keep their source archive.
```

**CBR-specific note**: `react-native-zip-archive` only handles ZIP. CBR is RAR format. Options:
- **Option A** (Recommended): Bundle a precompiled `libunrar.so` as a native module accessed via `react-native-blob-util` + JNI bridge. Requires custom dev client.
- **Option B** (Fallback): Reject CBR at import time in v1, add in v1.1. Show user-facing message: "CBR support coming soon — please convert to CBZ."

> [!NOTE]
> **✅ Decision Resolved**: CBR support (Option A — native `libunrar.so` bridge) is included in v1.

---

## 2.5 WebView Bridge Architecture (Book Engine)

`react-native-webview` runs epub.js/mammoth.js in a sandboxed WebView. Communication is bidirectional via `postMessage`:

```
RN → WebView (commands):
  { type: 'SET_THEME', payload: { bg, fg, fontFamily, fontSize } }
  { type: 'NAVIGATE_CFI', payload: { cfi: '...' } }
  { type: 'NAVIGATE_PAGE', payload: { page: 42 } }
  { type: 'GET_TOC' }

WebView → RN (events):
  { type: 'LOCATION_CHANGE', payload: { cfi, page, percentage } }
  { type: 'TOC_READY', payload: { toc: [...] } }
  { type: 'TEXT_SELECTED', payload: { text, cfi } }
  { type: 'READY' }
```

The WebView HTML is a **local asset** (`assets/reader/index.html`) — no network access needed. epub.js and mammoth.js are bundled into this local HTML file.

---
---

# Part 3 — Database Schema (expo-sqlite)

## 3.1 Schema Design Principles
- Strictly relational, no JSON "abuse" for queryable fields.
- `progress_data` and `location_data` are the *only* JSON blob fields — used for engine-specific opaque data.
- `ON DELETE CASCADE` ensures highlights are cleaned up when a document is deleted.
- All timestamps are ISO 8601 strings (SQLite has no native datetime type).

---

## 3.2 Table: `documents`

```sql
CREATE TABLE IF NOT EXISTS documents (
  id            TEXT PRIMARY KEY,          -- UUID v4
  title         TEXT NOT NULL,
  author        TEXT,
  media_type    TEXT NOT NULL              -- CHECK enforced below
                  CHECK (media_type IN ('book', 'comic')),
  file_type     TEXT NOT NULL              -- 'epub' | 'docx' | 'pdf' | 'cbz' | 'cbr'
                  CHECK (file_type IN ('epub', 'docx', 'pdf', 'cbz', 'cbr')),
  cover_uri     TEXT,                      -- absolute path to thumbnail in cacheDir/covers/
  file_uri      TEXT NOT NULL,             -- absolute path to source file
  file_size     INTEGER,                   -- bytes
  total_pages   INTEGER,                   -- populated after first open
  progress_data TEXT,                      -- JSON blob: engine-specific location
  is_temporary  INTEGER NOT NULL DEFAULT 1 -- 0 = permanent, 1 = temp (SQLite bool)
                  CHECK (is_temporary IN (0, 1)),
  created_at    TEXT NOT NULL,             -- ISO 8601
  last_read_at  TEXT,                      -- ISO 8601, NULL until first open
  added_at      TEXT                       -- ISO 8601, set when promoted from temp
);

CREATE INDEX idx_documents_media_type ON documents(media_type);
CREATE INDEX idx_documents_last_read  ON documents(last_read_at DESC);
```

**`progress_data` JSON Schemas by engine:**

```jsonc
// EPUB / DOCX (epub.js CFI-based)
{ "cfi": "epubcfi(/6/4[chap01]!/4/2/1:0)", "percentage": 0.34 }

// PDF (page-based)
{ "page": 42, "totalPages": 210, "percentage": 0.20 }

// CBZ / CBR (image index)
{ "currentPage": 87, "totalPages": 248 }
```

---

## 3.3 Table: `highlights`

```sql
CREATE TABLE IF NOT EXISTS highlights (
  id            TEXT PRIMARY KEY,          -- UUID v4
  document_id   TEXT NOT NULL
                  REFERENCES documents(id) ON DELETE CASCADE,
  location_data TEXT NOT NULL,             -- JSON: { cfi } for epub, { page, rect } for pdf
  text_snippet  TEXT NOT NULL,             -- the highlighted text (max 2000 chars)
  color_hex     TEXT NOT NULL DEFAULT '#FFEB3B', -- e.g. '#FF5252'
  note          TEXT,                      -- optional user annotation
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL
);

CREATE INDEX idx_highlights_document ON highlights(document_id);
```

---

## 3.4 Table: `settings`

```sql
CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Seed values (inserted on first launch):
-- ('theme', 'dark')
-- ('book_font_family', 'serif')
-- ('book_font_size', '16')
-- ('comic_reading_mode', 'horizontal')
-- ('schema_version', '1')
```

---

## 3.5 Entity Relationship Diagram

```
documents (1) ──────< highlights (N)
   id ──────────────── document_id [FK, CASCADE DELETE]
```

---

## 3.6 Migration Strategy
- Schema version tracked in `settings` table (`schema_version`).
- On app launch, `DatabaseService.migrate()` runs:
  1. Read current `schema_version`.
  2. Execute any pending migration scripts (`migrations/v2.sql`, etc.).
  3. Bump `schema_version`.
- Migrations are additive only (no destructive column drops in v1).

---
---

# Part 4 — UI/UX Component Hierarchy

## 4.1 Expo Router File Structure

```
app/
├── _layout.tsx                   # Root layout: fonts, theme provider, DB init
├── (tabs)/                       # Bottom tab group
│   ├── _layout.tsx               # Bottom tabs: Library | Recents | Settings
│   ├── library/
│   │   ├── _layout.tsx           # Top tabs: Books | Comics
│   │   ├── books.tsx             # Books grid screen
│   │   └── comics.tsx            # Comics grid screen
│   ├── recents.tsx               # Recently opened flat list
│   └── settings.tsx              # App settings
├── reader/
│   └── [id].tsx                  # Dynamic reader route
└── +not-found.tsx
```

---

## 4.2 Navigation Architecture

```
Root Stack
└── (tabs) [Bottom Tabs]
    ├── library/ [Top Tabs — MaterialTopTabNavigator]
    │   ├── books      → LibraryBooksScreen
    │   └── comics     → LibraryComicsScreen
    ├── recents        → RecentsScreen
    └── settings       → SettingsScreen
    
(Outside tabs, full-screen modal stack):
└── reader/[id]        → ReaderScreen
```

> [!NOTE]
> `reader/[id]` is intentionally **outside** the tab group so the reader renders full-screen without the bottom tab bar visible. It uses a slide-up modal presentation.

---

## 4.3 Component Tree

### 4.3.1 Library Layer

```
LibraryBooksScreen / LibraryComicsScreen
└── ScreenContainer (SafeAreaView + StatusBar)
    ├── SearchBar (collapsible on scroll)
    ├── DocumentGrid
    │   └── FlatList / FlashList
    │       └── DocumentCard (reusable)
    │           ├── CoverImage (expo-image, with placeholder)
    │           ├── TitleText
    │           ├── ProgressBar (thin, bottom of card)
    │           └── TemporaryBadge (conditional "Not Saved" chip)
    └── ImportFAB (fixed position, bottom-right)
        └── triggers ImportService.ingest()
```

### 4.3.2 Reader Layer — Dynamic Route `/reader/[id]`

```
ReaderScreen  [app/reader/[id].tsx]
├── Loads document record from SQLite by id
├── Reads media_type field
│
├── if media_type === 'book'  →  BookEngine
│   ├── file_type === 'epub'  →  EpubReader (WebView + epub.js)
│   ├── file_type === 'docx'  →  DocxReader (WebView + mammoth.js)
│   └── file_type === 'pdf'   →  PdfReader  (react-native-pdf)
│
└── if media_type === 'comic' →  ComicEngine
    ├── ExtractionManager (windowed unzip)
    └── ComicViewer
        ├── mode === 'horizontal' → HorizontalPager (FlashList horizontal)
        └── mode === 'vertical'   → VerticalScroller (FlashList vertical)

Shared UI Overlays (both engines):
├── ReaderTopBar (animated slide-down on tap)
│   ├── BackButton
│   ├── DocumentTitle
│   └── OverflowMenu (Add to Library, Highlights, Share)
├── ReaderBottomBar (animated slide-up on tap)
│   ├── ProgressSlider
│   ├── PageIndicator ("12 / 248")
│   └── SettingsButton → ReaderSettingsSheet (BottomSheet)
└── ReaderSettingsSheet
    ├── [Books only] ThemePicker (Light/Sepia/Dark/AMOLED)
    ├── [Books only] FontFamilySelector
    ├── [Books only] FontSizeSlider
    └── [Comics only] ReadingModeToggle (Horizontal / Vertical)
```

### 4.3.3 Shared / Primitive Components

```
components/
├── ui/                         # react-native-reusables primitives
│   ├── Button.tsx
│   ├── Sheet.tsx               # BottomSheet wrapper
│   ├── Badge.tsx
│   └── Slider.tsx
├── library/
│   ├── DocumentCard.tsx
│   ├── DocumentGrid.tsx
│   └── ImportFAB.tsx
├── reader/
│   ├── BookEngine/
│   │   ├── EpubReader.tsx
│   │   ├── DocxReader.tsx
│   │   └── PdfReader.tsx
│   ├── ComicEngine/
│   │   ├── ComicViewer.tsx
│   │   ├── HorizontalPager.tsx
│   │   └── VerticalScroller.tsx
│   ├── ReaderTopBar.tsx
│   ├── ReaderBottomBar.tsx
│   └── ReaderSettingsSheet.tsx
└── common/
    ├── ScreenContainer.tsx
    ├── EmptyState.tsx
    └── LoadingSpinner.tsx
```

---

## 4.4 Data Flow per Screen

```
LibraryBooksScreen:
  useDocumentStore('book') → SELECT * FROM documents WHERE media_type='book' ORDER BY last_read_at DESC
  → renders DocumentGrid

ReaderScreen (/reader/[id]):
  1. useDocument(id) → SELECT * FROM documents WHERE id=?
  2. Mounts appropriate engine with file_uri + progress_data
  3. Engine fires onLocationChange → useProgressSave(id) → UPDATE documents SET progress_data=?, last_read_at=? WHERE id=?
  4. Unmount → ComicEngine cleanup (delete extracted images)
```

---
---

# Part 5 — Phased Implementation Roadmap

## Phase 1: Foundation
**Goal**: Runnable app shell with DB and native module access.

| Task | Details |
|---|---|
| Project Init | `npx create-expo-app@latest` with blank TypeScript template |
| NativeWind v4 Config | Install + configure `babel.config.js`, `metro.config.js`, `global.css` |
| react-native-reusables | Init CLI, copy required components |
| Expo Router Setup | Configure `app/_layout.tsx`, entry point |
| Custom Dev Client | `expo prebuild --platform android`, build dev client APK |
| SQLite Init | `DatabaseService` class, run `CREATE TABLE` migrations on startup |
| File System Dirs | Create `library/books/`, `library/comics/`, `covers/`, `imports/` on first launch |

**Exit Criteria**: App launches on device/emulator. SQLite schema verified via `expo-sqlite` inspector.

---

## Phase 2: Library UI Shell
**Goal**: Complete navigation structure and library screens with mock data.

| Task | Details |
|---|---|
| Bottom Tabs | `(tabs)/_layout.tsx` — Library, Recents, Settings icons |
| Top Tabs | `library/_layout.tsx` using `@react-navigation/material-top-tabs` |
| DocumentCard | Cover image, title, progress bar, temporary badge |
| DocumentGrid | Responsive 2-column grid, empty state illustration |
| RecentsScreen | Flat list, grouped by date |
| SettingsScreen | Theme toggle, comic mode preference, clear cache |
| NativeWind Theming | Dark/light color tokens, custom font loading via `expo-font` |

**Exit Criteria**: Full navigation works. Library renders mock cards. Theme toggle applies globally.

---

## Phase 3: File Import Pipeline
**Goal**: Real files can be imported, categorized, and stored.

| Task | Details |
|---|---|
| `expo-document-picker` | FAB triggers picker with accepted MIME types |
| `ImportService` | Extension → media_type/file_type mapping, UUID rename, cache copy |
| Cover Extraction | EPUB: unzip cover. PDF: page-0 render. DOCX: placeholder. CBZ: first image |
| SQLite Insert | `documents` INSERT with `is_temporary = 1` |
| "Add to Library" | Copy file cache → documentDirectory, UPDATE record |
| Intent Intercept | `AndroidManifest` intent filters for external file opens |
| Error Handling | Unsupported format toast, disk full error, duplicate detection |

**Exit Criteria**: Import a real EPUB and CBZ. Both appear in correct library tabs. "Add to Library" persists file.

---

## Phase 4: Book Engines
**Goal**: All three book formats are readable with full controls.

| Task | Details |
|---|---|
| Local WebView Asset | Bundle `assets/reader/index.html` with epub.js + mammoth.js |
| EPUB Engine | WebView bridge: load CFI, theme apply, TOC extraction |
| DOCX Engine | mammoth.js HTML conversion inside WebView, same theme bridge |
| PDF Engine | `react-native-pdf` integration, page tracking |
| Progress Persistence | `onLocationChange` → debounced SQLite UPDATE |
| Theme System | ReaderSettingsSheet wired to WebView postMessage |
| Highlights (EPUB) | Text selection → highlight insert → highlights table |
| TOC Drawer | Slide-in drawer from left, navigates to CFI on tap |

**Exit Criteria**: Open a real EPUB. Change theme. Close and reopen — position restored. Add a highlight.

---

## Phase 5: Comic Engine
**Goal**: CBZ comics render with both reading modes and efficient memory use.

| Task | Details |
|---|---|
| `react-native-zip-archive` | Extract CBZ pages to `cacheDirectory/extracted/{uuid}/` |
| Windowed Extraction | Prefetch logic: extract pages N to N+5, delete N-6 and earlier |
| `ExtractionManager` | Background extraction queue, emits progress events |
| `HorizontalPager` | FlashList horizontal, page snap, double-tap zoom |
| `VerticalScroller` | FlashList vertical, long-strip mode |
| Reading Mode Toggle | Seamless switch without losing page position |
| Page Indicator | "12 / 248" overlay, auto-dismiss after 2s |
| Cleanup on Exit | Delete all extracted images, save page progress to SQLite |
| CBR Decision | Implement Option A/B per approved decision |

**Exit Criteria**: Open a 200-page CBZ. Switch between horizontal/vertical modes. Close and reopen at saved page.

---

## Phase 6: Polish & Optimization
**Goal**: Production-quality experience.

| Task | Details |
|---|---|
| Reading Stats | Time spent per session, total pages read (stored in settings table) |
| Recents Screen | Populated from real `last_read_at` data |
| Search | In-library full-text search on title/author |
| Sort & Filter | By last read, title A-Z, file type, size |
| Performance Audit | FlashList `estimatedItemSize` tuning, WebView preload |
| Accessibility | Content descriptions for screen readers, font scaling |
| Splash Screen | Custom splash via `expo-splash-screen` |
| App Icon | Custom launcher icon |
| Error Boundaries | React error boundary on both engines with friendly fallback UI |
| Cache Management | Settings screen "Clear Cache" — deletes `cacheDirectory/imports/` and `extracted/` |

**Exit Criteria**: App passes manual QA checklist. Memory usage stable during 200-page comic read.

---

## Dependency Table (All Packages)

| Package | Version Constraint | Purpose |
|---|---|---|
| `expo` | SDK 52+ | Core runtime |
| `expo-router` | v4 | File-based navigation |
| `nativewind` | v4 | Tailwind for RN |
| `react-native-reusables` | latest | shadcn UI components |
| `expo-sqlite` | latest | Relational local DB |
| `expo-file-system` | latest | File read/write/copy |
| `expo-document-picker` | latest | Native file picker |
| `react-native-webview` | latest | Book rendering host |
| `react-native-pdf` | latest | PDF rendering |
| `react-native-zip-archive` | latest | CBZ extraction |
| `@shopify/flash-list` | latest | High-perf image list |
| `@react-navigation/material-top-tabs` | v7 | Top tab navigator |
| `expo-image` | latest | Optimized cover images |
| `expo-font` | latest | Custom typography |
| `react-native-blob-util` | latest | Binary file ops (CBR) |
| `zustand` | v5 | Global UI + import state |

---

> [!NOTE]
> **✅ All decisions resolved. Phase 1 execution in progress.**
> - CBR: Option A (native unrar bridge in v1)
> - State Management: Zustand v5 with persist middleware

