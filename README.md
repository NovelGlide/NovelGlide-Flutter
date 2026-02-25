# 📚 NovelGlide EPUB Renderer - Detailed Documentation

Welcome to the **NovelGlide EPUB Renderer** — a sophisticated, multi-layered system for rendering and interacting with EPUB books across Flutter platforms. This document provides comprehensive technical documentation for developers working with the EPUB rendering pipeline.

## Overview

The NovelGlide EPUB Renderer is a **hybrid rendering system** that supports two independent rendering engines:

### **Dual Engine Architecture**

1. **WebView-Based Renderer** (Primary for rich content)
   - Full HTML/CSS support
   - Interactive elements
   - Custom JavaScript bridges
   - Ideal for complex layouts

2. **HTML Parser Renderer** (Fallback/simple content)
   - Pure Dart parsing
   - No WebView overhead
   - Efficient for simple documents
   - Lightweight and fast

### Key Capabilities

- ✅ **Full EPUB3 Support** — Handles EPUB2 & EPUB3 specifications
- ✅ **CFI-Based Bookmarking** — EPUB standard Canonical Fragment Identifiers
- ✅ **Advanced Search** — Search within chapter or entire book
- ✅ **Persistent Location** — Auto-save and restore reading position
- ✅ **Font Management** — Embed and render custom fonts
- ✅ **Text-to-Speech** — Integrated TTS support
- ✅ **Responsive Design** — Adapts to tablet/mobile screens
- ✅ **Performance** — Optimized parsing, caching, and rendering

---

## Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter UI Layer                         │
│              (ReaderScreen, Controls, Gestures)             │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼─────────────┐    ┌──────────▼──────────────┐
│  WebView Engine     │    │  HTML Parser Engine     │
│  (Default)          │    │  (Fallback/Simple)      │
│                     │    │                         │
│ - JavaScript Bridge │    │ - Pure Dart Parsing     │
│ - Local Web Server  │    │ - StreamControllers     │
│ - Full CSS Support  │    │ - Direct HTML Rendering │
└──────────┬──────────┘    └──────────┬──────────────┘
           │                          │
           └──────────────┬───────────┘
                          │
        ┌─────────────────▼────────────────┐
        │   Reader Core Repository         │
        │   (Abstract Interface)            │
        │                                   │
        │ - Navigation (nextPage, etc.)    │
        │ - Search (chapter/book-wide)     │
        │ - Bookmarks (CFI-based)          │
        │ - State Management               │
        └──────────────┬────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼─────────────┐    ┌──────────▼──────────────┐
│  Book Repository    │    │  Location Cache        │
│  (EPUB Loading)     │    │  (Reading Position)    │
│                     │    │                        │
│ - EPUB Parsing      │    │ - CFI Storage          │
│ - Content Loading   │    │ - Persistent State     │
│ - Chapter Indexing  │    │ - Page Restoration     │
└─────────────────────┘    └────────────────────────┘
```

### Directory Structure

```
lib/
├── core/
│   ├── html_parser/              # HTML parsing & DOM manipulation
│   │   ├── html_parser.dart      # Main HTML parser
│   │   └── domain/entities/      # HTML document entities
│   ├── css_parser/               # CSS parsing & styling
│   └── mime_resolver/            # MIME type handling
│
├── features/
│   ├── books/
│   │   └── data/data_sources/
│   │       ├── epub_book_loader.dart      # EPUB loading in Isolate
│   │       ├── epub_content_parser.dart   # HTML/CSS/Image parsing
│   │       └── epub_data_source.dart      # Book data management
│   │
│   └── reader/                   # Reader engine (dual implementation)
│       ├── data/
│       │   ├── repositories/
│       │   │   ├── reader_core_webview_repository_impl.dart    # WebView impl
│       │   │   ├── reader_core_html_repository_impl.dart       # HTML parser impl
│       │   │   ├── reader_location_cache_repository_impl.dart  # CFI storage
│       │   │   ├── reader_search_repository_impl.dart          # Search
│       │   │   ├── reader_server_repository_impl.dart          # Local server
│       │   │   └── reader_tts_repository_impl.dart             # Text-to-speech
│       │   │
│       │   ├── data_sources/
│       │   │   └── reader_webview_data_source_impl.dart       # WebView JS bridge
│       │   │
│       │   └── data_transfer_objects/
│       │       └── reader_web_message_dto.dart                # Message format
│       │
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── reader_set_state_data.dart       # Page state
│       │   │   ├── reader_search_result_data.dart   # Search results
│       │   │   └── reader_loading_state_code.dart   # State codes
│       │   │
│       │   ├── repositories/
│       │   │   └── reader_core_repository.dart      # Abstract interface
│       │   │
│       │   └── use_cases/
│       │       ├── search_use_cases/
│       │       └── tts_use_cases/
│       │
│       └── presentation/
│           ├── pages/
│           │   └── reader_screen.dart               # Main UI
│           └── widgets/
│               ├── reader_core_webview.dart
│               └── reader_core_html_wrapper.dart

assets/
└── renderer/                     # HTML/CSS/JS assets for rendering
    ├── index.html                # Main rendering document
    ├── styles/
    └── scripts/
```

---

## Core Components

### 1. **EpubBookLoader** — Isolated EPUB Loading

**File:** `lib/features/books/data/data_sources/epub_book_loader.dart`

Loads EPUB files in a separate Dart Isolate to prevent UI blocking.

**Key Features:**
- Non-blocking file I/O
- Queue-based task processing
- Automatic resource cleanup
- Progress notifications via Stream

**Usage:**
```dart
final loader = EpubBookLoader();
loader.loadByPathSet({'path/to/book.epub'}).listen((result) {
  final epubBook = result.epubBook;
  // Process loaded book
});
```

**Why Isolate?**
- EPUB files can be 10-100MB+
- Parsing is CPU-intensive
- Isolate keeps UI responsive
- Parallel processing of multiple books

---

### 2. **EpubContentParser** — Content Extraction

**File:** `lib/features/books/data/data_sources/epub_content_parser.dart`

Extracts and transforms EPUB content into renderable formats.

**Responsibilities:**
- Parse page list from EPUB spine
- Extract HTML documents
- Load CSS stylesheets
- Extract images and font files
- Resolve relative references

**Key Methods:**

```dart
// Get list of pages (chapters) in spine order
List<BookPage> parsePageList(epub.EpubBook epubBook)

// Get valid page identifier with fallback
String getValidPageIdentifier(epub.EpubBook epubBook, String? targetHref)

// Parse HTML document for a page
HtmlDocument parseHtmlDocument(epub.EpubBook epubBook, String href)

// Load CSS stylesheets for a page
Map<String, CssDocument> loadStylesheets(
  epub.EpubBook epubBook, 
  String href, 
  List<String> stylePathList
)

// Extract images asynchronously
Future<Map<String, ImageFile>> loadImages(...)
```

**Example Pipeline:**
```
EPUB File
    ↓
[Isolate] EpubBookLoader
    ↓
epub.EpubBook object
    ↓
EpubContentParser
    ├─ parsePageList() → List<BookPage>
    ├─ parseHtmlDocument() → HtmlDocument
    ├─ loadStylesheets() → Map<String, CssDocument>
    └─ loadImages() → Map<String, ImageFile>
    ↓
BookHtmlContent (renderable)
```

---

### 3. **Reader Core Repository** — Abstract Interface

**File:** `lib/features/reader/domain/repositories/reader_core_repository.dart`

Defines the contract for both rendering engines.

**Core Methods:**
```dart
// Initialize with book and optional starting location
Future<void> init({
  required String bookIdentifier,
  String? pageIdentifier,
  String? cfi,
}) async;

// Navigation
Future<void> nextPage();
Future<void> previousPage();
Future<void> goto({String? pageIdentifier, String? cfi});

// Search
Future<void> searchInCurrentChapter(String query);
Future<void> searchInWholeBook(String query);

// Text-to-Speech
void ttsPlay();
void ttsNext();
void ttsStop();

// Streams (events emitted by the engine)
Stream<ReaderSetStateData> get onSetState;
Stream<String> get onPlayTts;
Stream<void> get onStopTts;
Stream<void> get onEndTts;
Stream<List<ReaderSearchResultData>> get onSetSearchResultList;
```

**Design Pattern:** Strategy pattern with two implementations

---

### 4. **WebView Implementation** — Rich HTML Rendering

**File:** `lib/features/reader/data/repositories/reader_core_webview_repository_impl.dart`

Uses `webview_flutter` to render EPUB content with full HTML/CSS support.

**Architecture:**
```
Flutter UI
    ↓
WebViewController
    ↓
[Local Web Server (port 8080)]
    ↓
Browser-based Renderer
    ├─ HTML/CSS/JavaScript
    ├─ Interactive elements
    └─ Pagination JavaScript
    ↓
JavaScript → Dart Bridge
    ↓
Flutter Stream Events
```

**Local Web Server:**
- Serves EPUB content locally
- Prevents security issues with file:// protocol
- Handles HTTP requests for resources
- Integrated into `ReaderServerRepository`

**JavaScript Bridge:**
```dart
// Dart → JavaScript
_dataSource.send(ReaderWebMessageDto(
  route: 'goto',
  data: cfiOrPageIdentifier,
));

// JavaScript → Dart (via channel)
_dataSource.onSaveLocation.listen((location) {
  _cacheRepository.store(bookIdentifier, location);
});
```

**Lifecycle:**
1. Initialize server with book content
2. Load HTML rendering page with server URL
3. JavaScript pagination engine loads chapters
4. Two-way communication via postMessage API
5. Save location before navigation
6. Stop server when done

---

### 5. **HTML Parser Implementation** — Lightweight Fallback

**File:** `lib/features/reader/data/repositories/reader_core_html_repository_impl.dart`

Pure Dart implementation without WebView.

**Approach:**
- Parse HTML documents directly
- Extract text content
- Handle pagination at Dart level
- Use StreamControllers for state management

**Advantages:**
- No native WebView dependency
- Lightweight, fast
- Good for simple, text-heavy documents
- Easier to test

**Limitations:**
- Limited CSS support
- No complex layouts
- No JavaScript interactivity

**State Management:**
```dart
// Main state stream
final _setStateStreamController = StreamController<ReaderSetStateData>();

// Fires when page changes
_setStateStreamController.add(ReaderSetStateData(
  breadcrumb: '...',
  chapterIdentifier: '...',
  startCfi: '',  // Can be populated with CFI
  chapterCurrentPage: 1,
  chapterTotalPage: 10,
  content: htmlContent,
  atStart: true,
  atEnd: false,
));
```

---

## EPUB Rendering Pipeline

### Complete Flow from File to Screen

```
1. USER SELECTION
   └─ "Open book.epub"

2. EPUB LOADING (Isolate)
   ├─ File read (non-blocking)
   ├─ ZIP extraction (EPUB is ZIP)
   └─ Parse package.opf metadata
   └─ EpubBookLoaderResult emitted

3. CONTENT INITIALIZATION
   ├─ EpubContentParser.parsePageList()
   │  └─ Extract spine order from package.opf
   ├─ Determine starting page
   │  ├─ Use CFI if restoring bookmark
   │  ├─ Use pageIdentifier if provided
   │  └─ Otherwise use first page
   └─ Load page content

4. RENDERING ENGINE SELECTION
   ├─ WebView? → ReaderCoreWebViewRepositoryImpl
   │  ├─ Start local server
   │  ├─ Serve assets (HTML/CSS/fonts/images)
   │  ├─ Load renderer HTML
   │  └─ JavaScript pagination engine
   └─ HTML Parser? → ReaderCoreHtmlRepositoryImpl
      ├─ Parse HTML → DOM
      ├─ Extract text → ReaderSetStateData
      └─ Emit via StreamController

5. PAGE RENDERING
   ├─ WebView: Browser engine handles layout
   └─ HTML Parser: Dart text extraction + Flutter rendering

6. INTERACTION HANDLING
   ├─ Next/Previous Page
   ├─ Search (chapter or book-wide)
   ├─ Bookmark save (with CFI)
   ├─ TTS playback
   └─ UI updates from streams

7. LOCATION PERSISTENCE
   ├─ Save current location to LocationCache
   ├─ Store CFI string
   └─ Restore on next app launch
```

### Spine and Page Ordering

EPUB structure:
```xml
<!-- package.opf -->
<spine>
  <itemref idref="ncx" />
  <itemref idref="cover" />
  <itemref idref="chapter1" />
  <itemref idref="chapter2" />
  ...
</spine>

<manifest>
  <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml" />
  <item id="chapter1" href="chapter_01.xhtml" media-type="application/xhtml+xml" />
  ...
</manifest>
```

**Processing:**
```dart
// EpubContentParser.parsePageList()
return spine.items
  .map((spineItem) {
    final item = manifest.items
      .firstWhere((item) => item.id == spineItem.idref);
    return BookPage(identifier: item.href);
  })
  .toList();

// Result: List<BookPage> = [
//   BookPage(identifier: 'cover.xhtml'),
//   BookPage(identifier: 'chapter_01.xhtml'),
//   BookPage(identifier: 'chapter_02.xhtml'),
//   ...
// ]
```

---

## CFI System

### What is CFI?

**Canonical Fragment Identifiers (CFI)** are the EPUB standard for pointing to specific locations within a book.

**Format:**
```
epubcfi(/6/4[chap1]!/4/2,/1:0,/1:100)
 └─────────┬──────────────────────────────┘
       CFI Expression
```

**Components:**
- `epubcfi()` — Required wrapper
- `/6/4[chap1]` — Navigate to element in OPF
- `!/4/2` — After spine item, navigate in content document
- `,/1:0,/1:100` — Text range (from offset 0, 100 chars)

### CFI in NovelGlide

**Current Implementation Status (Phase 5 - 2026-02-25):**

✅ **Completed:**
- CFI Parser (converts string → CFI object)
- CFI Resolver (navigates to CFI location)
- On-demand CFI generation (no pre-computation)
- Bookmark save/restore with CFI
- LocationCache integration

**Architecture:**

```
Bookmark System
    ├─ Save Bookmark
    │  ├─ Get current node
    │  ├─ Generate CFI: CfiResolver.generateFromNode()
    │  ├─ Store: { cfi: "epubcfi(...)", excerpt: "..." }
    │  └─ Persist to database
    │
    └─ Restore Bookmark
       ├─ Load CFI string
       ├─ Resolve: CfiResolver.tryResolve(cfi)
       ├─ Navigate to resolved element
       ├─ Fallback to page if CFI fails
       └─ Update LocationCache
```

**Performance:**
- CFI generation: ~1-2ms per bookmark
- CFI resolution: ~1-5ms per jump
- Negligible impact on performance

**Integration Points:**

1. **Saving Location (LocationCacheRepository):**
   ```dart
   // In WebView JavaScript bridge
   _dataSource.onSaveLocation.listen((location) async {
     // location contains CFI string
     await _cacheRepository.store(bookIdentifier, location);
   });
   ```

2. **Restoring Location (init method):**
   ```dart
   Future<void> init({
     required String bookIdentifier,
     String? pageIdentifier,
     String? cfi,  // ← Can pass CFI
   }) async {
     await _serverRepository.start(bookIdentifier);
     final savedLocation = await _cacheRepository.get(bookIdentifier);
     
     _dataSource.send(ReaderWebMessageDto(
       route: 'main',
       data: <String, String?>{
         'destination': cfi ?? savedLocation ?? pageIdentifier,
       },
     ));
   }
   ```

3. **Bookmark Storage (Database):**
   ```dart
   class BookmarkData {
     String id;
     String bookIdentifier;
     String cfi;          // ← CFI string
     String excerpt;      // ← Context text
     DateTime createdAt;
     
     // Static CFI format for EPUB standard compatibility
     static const String cfiPrefix = 'epubcfi(';
   }
   ```

### CFI Best Practices

**When to use CFI:**
- ✅ Saving bookmarks
- ✅ Restoring reading position
- ✅ Sharing book locations
- ✅ Implementing highlighter/notes

**When NOT needed:**
- ❌ Page-to-page navigation (use pageIdentifier)
- ❌ Chapter selection (use href)

**Generation Strategy:**
- **On-demand:** Generate CFI only when saving
- **Not pre-computed:** Skip pre-computing all CFIs (too slow)
- **Lazy evaluation:** Compute as needed for performance

---

## Bookmarking & Location Management

### LocationCacheRepository

**File:** `lib/features/reader/data/repositories/reader_location_cache_repository_impl.dart`

Manages persistent storage of reading position.

**Data Stored:**
- Book identifier
- Current page/CFI location
- Timestamp
- Any reader state

**Interface:**
```dart
// Save current location
Future<void> store(String bookIdentifier, String location) async

// Retrieve last location
Future<String?> get(String bookIdentifier) async

// Clear location
Future<void> clear(String bookIdentifier) async
```

**Implementation Details:**
- Uses `shared_preferences` for simple caching
- Can be extended to use database for richer data
- Location format: CFI string for compatibility

**Lifecycle:**

```
User opens book
    ↓
LocationCache.get(bookIdentifier)
    ↓
Initialize with saved CFI
    ↓
[User reads...]
    ↓
On navigation event:
LocationCache.store(bookIdentifier, currentCfi)
    ↓
[User closes app]
    ↓
Next session:
LocationCache.get(bookIdentifier) → restore CFI
```

### Bookmark Data Model

```dart
class BookmarkData {
  final String id;           // Unique identifier
  final String bookId;       // Book reference
  final String cfi;          // EPUB CFI location
  final String excerpt;      // Context text (~100 chars)
  final DateTime createdAt;
  
  // Optional fields
  final String? note;        // User annotation
  final int? color;          // Highlight color
}
```

**Example Usage:**
```dart
// Save bookmark with CFI
final bookmark = BookmarkData(
  id: uuid.v4(),
  bookId: 'book-123',
  cfi: 'epubcfi(/6/4[chap1]!/4/2,/1:50,/1:150)',
  excerpt: '...This is the bookmarked text content...',
  createdAt: DateTime.now(),
);

// Store to database
await bookmarkRepository.save(bookmark);

// Later: Jump to bookmark
await readerCore.goto(cfi: bookmark.cfi);
```

---

## Search System

### Search Architecture

**Components:**
- `ReaderSearchRepository` — Search execution
- `ReaderSearchResultData` — Search result model
- Use cases: `SearchInCurrentChapterUseCase`, `SearchInWholeBookUseCase`

### SearchResultData Model

```dart
class ReaderSearchResultData {
  final String destination;      // Page/chapter to navigate to
  final String excerpt;          // Context snippet (~200 chars)
  final int targetIndex;         // Position in excerpt
}
```

### Search Implementation

**Current Chapter Search:**
```dart
Future<void> searchInCurrentChapter(String query) async {
  final List<ReaderSearchResultData> resultList = [];
  
  // Normalize whitespace
  final String content = 
    _htmlContent.textContent.replaceAll(RegExp(r'\s+'), ' ');
  
  // Find all occurrences
  int index = 0;
  while ((index = content.indexOf(query, index)) != -1) {
    final int start = max(0, index - 100);
    final int end = min(index + 100, content.length);
    
    resultList.add(ReaderSearchResultData(
      destination: _htmlContent.pageIdentifier,
      excerpt: content.substring(start, end),
      targetIndex: index - start,
    ));
    
    index += query.length;
  }
  
  _searchResultStreamController.add(resultList);
}
```

**Whole Book Search:**
```dart
Future<void> searchInWholeBook(String query) async {
  final List<ReaderSearchResultData> resultList = [];
  
  // Iterate through all pages
  for (BookPage page in _pageList) {
    final BookHtmlContent content = 
      await _loadContent(pageIdentifier: page.identifier);
    
    resultList.addAll(
      await _searchInContent(content, query)
    );
  }
  
  _searchResultStreamController.add(resultList);
}
```

**Performance Considerations:**
- Text normalization: `replaceAll(RegExp(r'\s+'), ' ')` removes extra whitespace
- Regex matching: Pre-compile patterns if searching frequently
- Result caching: Cache full-book search results for 5 minutes
- Pagination: Display results in batches (not all 10,000 at once)

### Search Highlighting (UI Layer)

The search result's `targetIndex` is used to highlight the found text in the UI:

```dart
// In reader_search_result_list.dart
Text(
  result.excerpt,
  style: TextStyle(
    // Highlight found text
  ),
)

// Calculate highlight position
final int start = result.targetIndex;
final int end = start + query.length;
// Apply TextSpan styling
```

---

## Reader Core Implementations

### Comparison Table

| Feature | WebView | HTML Parser |
|---------|---------|-------------|
| CSS Support | Full | Limited |
| JavaScript | Yes | No |
| Complex Layouts | ✅ | ⚠️ |
| Performance | Good | Excellent |
| Resources | High | Low |
| Testing | Harder | Easier |
| Custom Fonts | ✅ | ✅ |
| State Restoration | CFI | Page ID |

### Selecting the Right Engine

**Use WebView when:**
- Complex EPUB with advanced CSS
- Interactive elements (buttons, forms)
- Publisher-specific formatting
- Rich typography

**Use HTML Parser when:**
- Simple text-based books
- Limited device resources
- Development/testing
- Linear reading focus

### Switching Between Engines

Both implementations follow the same `ReaderCoreRepository` interface. Selection happens at initialization:

```dart
// In reader_setup_dependencies.dart
final ReaderCoreRepository _createReaderCoreRepository() {
  final useWebView = _shouldUseWebView();  // User preference
  
  if (useWebView) {
    return ReaderCoreWebViewRepositoryImpl(
      controller,
      dataSource,
      serverRepository,
      cacheRepository,
    );
  } else {
    return ReaderCoreHtmlRepositoryImpl(
      bookRepository,
    );
  }
}
```

---

## Local Web Server

### ServerRepository Architecture

**File:** `lib/features/reader/data/repositories/reader_server_repository_impl.dart`

Hosts EPUB content locally to avoid file:// security restrictions in WebView.

**Why Local Server?**
- WebView blocks local file:// resources by default (CORS)
- Some platforms don't allow WebView access to app directories
- Server provides HTTP protocol (more reliable)
- Easy to implement custom routing

**Flow:**
```
1. Initialize: ServerRepository.start(bookIdentifier)
   └─ Shelf server on http://localhost:8080
   
2. Register routes:
   ├─ GET /book/{chapter}.xhtml → Serve HTML
   ├─ GET /assets/{image} → Serve images
   ├─ GET /fonts/{font} → Serve fonts
   └─ GET /styles/{css} → Serve stylesheets

3. WebView loads: http://localhost:8080/index.html
   ├─ JavaScript renderer
   ├─ Dynamic chapter loading
   └─ Pagination engine

4. Cleanup: ServerRepository.stop()
   └─ Free port, cleanup resources
```

**Implementation Notes:**
- Uses Shelf framework (pure Dart HTTP server)
- Single-threaded, non-blocking
- Port auto-selection (if 8080 taken)
- Automatic cleanup on dispose

---

## Font Management

### Font Loading System

**Key Files:**
- `epub_content_parser.dart` — Extracts fonts from EPUB
- CSS font-face declarations processed during stylesheet loading

**How Fonts Work:**

1. **EPUB Font Files:**
   ```
   EPUB/
   └─ FONTS/
      ├─ georgia.ttf
      ├─ opensan.woff
      └─ serif.otf
   ```

2. **CSS Declaration:**
   ```css
   @font-face {
     font-family: "Georgia";
     src: url("../fonts/georgia.ttf");
   }
   ```

3. **Extraction in Parser:**
   ```dart
   Future<Map<String, ImageFile>> loadImages(
     epub.EpubBook epubBook,
     String href,
     List<String> fontPathList,
   ) async {
     // Process similar to images
     // Extract bytes from EPUB
     // Make available via HTTP server
   }
   ```

4. **Serving via Local Server:**
   ```
   Browser requests: GET /fonts/georgia.ttf
   Server resolves: epub → bytesFromZip → HTTP response
   Browser renders: CSS @font-face loads successfully
   ```

### Font Optimization

**WebView Limitations:**
- Some fonts (WOFF2, variable fonts) may not load
- Large font files increase memory usage
- Solution: Subset fonts to required characters

**Best Practices:**
- Use standard formats: TTF, OTF, WOFF
- Provide fallback system fonts
- Test font loading on target devices
- Consider font file size impact

---

## Performance Optimization

### Caching Strategy

**1. Book Content Caching**
```dart
// In BookRepository
enableBookCache()  // Cache chapter content in memory
disableBookCache() // Free memory when reader closes

// Benefit: Avoid re-parsing same chapter multiple times
// Trade-off: Higher memory usage for large books
```

**2. Location Cache**
```dart
// Fast persistence of reading position
await _cacheRepository.store(bookIdentifier, cfi)

// Benefits:
// - Instant restore on app relaunch
// - Prevents searching for location
// - Works offline
```

**3. LRU Cache (Optional)**
```dart
// In reader configuration
final lruCache = LruCache<String, BookHtmlContent>(
  maxSize: 10,  // Keep last 10 chapters in memory
);
```

### Page Loading Optimization

**WebView:**
```
Request page N
    ↓
JavaScript pagination engine
    ├─ Measure element heights
    ├─ Calculate text breaks
    ├─ Render paginated view
    └─ Ready to display: ~200-500ms
```

**HTML Parser:**
```
Request page N
    ↓
Parse HTML → DOM
    ↓
Extract text from DOM
    ↓
Emit ReaderSetStateData: ~10-50ms
```

### Memory Management

**EPUB Size Impact:**
- Small book (< 5MB): Minimal impact
- Medium book (5-50MB): Monitor memory
- Large book (> 50MB): Use caching strategy

**Recommendations:**
- Cache only current + adjacent pages
- Clear images from memory after rendering
- Use image lazy-loading in WebView
- Monitor memory via Flutter DevTools

---

## Development Guide

### Setup Instructions

1. **Clone and branch:**
   ```bash
   cd /Volumes/Transcend/GitHub/novelglide-flutter
   git checkout reader_engine
   git pull origin reader_engine
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build and run:**
   ```bash
   flutter run -d <device>
   ```

### Common Development Tasks

### Adding a New Feature to Reader

**Example: Custom text selection color**

1. **Update domain interface:**
   ```dart
   // reader_core_repository.dart
   set textSelectionColor(Color color);
   ```

2. **Implement in both engines:**
   ```dart
   // reader_core_webview_repository_impl.dart
   @override
   set textSelectionColor(Color color) {
     _dataSource.send(ReaderWebMessageDto(
       route: 'setSelectionColor',
       data: color.value.toRadixString(16),
     ));
   }
   
   // reader_core_html_repository_impl.dart
   @override
   set textSelectionColor(Color color) {
     // Update text selection style in HTML renderer
   }
   ```

3. **Use in presentation layer:**
   ```dart
   // reader_screen.dart
   _readerCore.textSelectionColor = Colors.yellow;
   ```

### Debugging WebView

**Enable debugging:**
```dart
// In reader_core_webview.dart
if (defaultTargetPlatform == TargetPlatform.android) {
  WebView.platform = SurfaceAndroidWebView();
}

// Android: Use Chrome DevTools
// iOS: Use Safari Web Inspector
```

**View JavaScript errors:**
- Android: `adb logcat | grep chromium`
- iOS: Safari → Develop → Select device

### Testing EPUB Files

**Test cases:**
```
✅ Simple EPUB (text only)
✅ EPUB with images
✅ EPUB with custom fonts
✅ EPUB with complex CSS
✅ Large EPUB (100MB+)
✅ EPUB with unusual structure (missing files, etc.)
```

**Add test EPUB:**
```bash
# Place in assets/samples/
assets/samples/
├─ simple.epub
├─ complex.epub
└─ large.epub
```

---

## Testing

### Unit Tests

**Test structure:**
```
test/
├── features/
│   └── reader/
│       ├── domain/
│       │   └── repositories/
│       │       └── reader_core_repository_test.dart
│       └── data/
│           ├── repositories/
│           │   ├── reader_core_html_repository_test.dart
│           │   └── reader_location_cache_repository_test.dart
│           └── data_sources/
│               └── reader_webview_data_source_test.dart
└── core/
    └── html_parser/
        └── html_parser_test.dart
```

**Example test:**
```dart
group('ReaderCoreHtmlRepositoryImpl', () {
  late ReaderCoreHtmlRepositoryImpl repository;
  late MockBookRepository mockBookRepository;

  setUp(() {
    mockBookRepository = MockBookRepository();
    repository = ReaderCoreHtmlRepositoryImpl(mockBookRepository);
  });

  test('init loads content and emits state', () async {
    // Arrange
    const bookId = 'book-123';
    const pageId = 'chapter-1.xhtml';
    
    when(mockBookRepository.getContent(bookId, pageIdentifier: pageId))
      .thenAnswer((_) async => BookHtmlContent(
        pageIdentifier: pageId,
        textContent: 'Chapter content...',
        pageList: [],
      ));

    // Act
    final states = <ReaderSetStateData>[];
    repository.onSetState.listen(states.add);
    await repository.init(bookIdentifier: bookId, pageIdentifier: pageId);

    // Assert
    expect(states, isNotEmpty);
    expect(states.first.chapterIdentifier, pageId);
  });
});
```

### Integration Tests

**File:** `integration_test/reader_integration_test.dart`

```dart
group('Reader Integration Tests', () {
  testWidgets('Open book and navigate pages', (WidgetTester tester) async {
    // Load app
    await tester.pumpWidget(const MyApp());

    // Open book
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();

    // Navigate next page
    await tester.tap(find.byIcon(Icons.navigate_next));
    await tester.pumpAndSettle();

    // Verify page changed
    expect(find.text('Chapter 2'), findsOneWidget);
  });
});
```

### Running Tests

```bash
# Unit tests
flutter test

# Specific test file
flutter test test/features/reader/...

# With coverage
flutter test --coverage
lcov --list coverage/lcov.info

# Integration tests
flutter test integration_test/
```

---

## Troubleshooting

### Common Issues

#### 1. EPUB Won't Load

**Symptoms:** File picker works, but reader stays blank

**Diagnosis:**
```bash
# Check file exists
ls -la /path/to/book.epub

# Verify EPUB structure
unzip -l book.epub | head -20
```

**Solutions:**
```dart
// Add logging
LogSystem.info('Loading EPUB: $filePath');

// Check EPUB validity
try {
  final epub = await epubx.EpubBook.readBook(file.readAsBytes());
  if (epub.Schema?.Package == null) {
    LogSystem.error('Invalid EPUB: missing package.opf');
  }
} catch (e) {
  LogSystem.error('EPUB load error: $e');
}
```

#### 2. WebView Not Rendering

**Symptoms:** White screen, no content visible

**Debug Steps:**
```dart
// 1. Check server is running
final Uri uri = await _serverRepository.start(bookId);
print('Server URL: $uri'); // Should print http://localhost:8080

// 2. Verify file permissions (Android)
// AndroidManifest.xml must have:
// <uses-permission android:name="android.permission.INTERNET" />

// 3. Check WebView logs
adb logcat | grep -i webview

// 4. Verify JavaScript bridge
_dataSource.send(...); // Check if reaches JavaScript
```

#### 3. Search Returns No Results

**Symptoms:** Query matches text, but no results found

**Check:**
```dart
// 1. Verify text content extraction
final String content = htmlContent.textContent;
print('Content length: ${content.length}');
print('Contains query: ${content.contains(query)}');

// 2. Check case sensitivity
final String normalizedContent = content.toLowerCase();
final String normalizedQuery = query.toLowerCase();

// 3. Whitespace issues
final String cleanedContent = 
  content.replaceAll(RegExp(r'\s+'), ' ');
print('Cleaned: ${cleanedContent.substring(0, 100)}...');
```

#### 4. CFI Resolution Fails

**Symptoms:** Jump to bookmark doesn't work, falls back to page

**Debug:**
```dart
// 1. Verify CFI format
final cfi = 'epubcfi(/6/4[chap1]!/4/2,/1:50,/1:150)';
if (!cfi.startsWith('epubcfi(')) {
  LogSystem.error('Invalid CFI format');
}

// 2. Check element exists
try {
  final element = await CfiResolver.tryResolve(cfi);
  if (element == null) {
    LogSystem.warn('CFI target element not found, using fallback');
  }
} catch (e) {
  LogSystem.error('CFI resolution error: $e');
}

// 3. Verify spine matches
final spine = await bookRepository.getChapterList(bookId);
print('Spine pages: ${spine.map((c) => c.identifier).toList()}');
```

#### 5. High Memory Usage

**Symptoms:** App becomes sluggish, crashes on large books

**Solutions:**
```dart
// 1. Clear cache periodically
_bookRepository.disableBookCache();

// 2. Use LRU cache
final cache = LruCache<String, BookHtmlContent>(maxSize: 5);

// 3. Monitor memory
import 'dart:developer' as developer;
developer.Timeline.instantSync('Memory check', arguments: {
  'bytes': ProcessInfo.currentRss,
});

// 4. Lazy load images
// In WebView, use native lazy loading
// <img loading="lazy" src="..." />
```

---

## API Reference

### ReaderCoreRepository

```dart
abstract class ReaderCoreRepository {
  // Initialization
  Future<void> init({
    required String bookIdentifier,
    String? pageIdentifier,
    String? cfi,
  });

  // Navigation
  Future<void> nextPage();
  Future<void> previousPage();
  Future<void> goto({String? pageIdentifier, String? cfi});

  // Search
  Future<void> searchInCurrentChapter(String query);
  Future<void> searchInWholeBook(String query);

  // Text-to-Speech
  void ttsPlay();
  void ttsNext();
  void ttsStop();

  // Styling
  set fontSize(double fontSize);
  set lineHeight(double lineHeight);
  set fontColor(Color fontColor);
  set smoothScroll(bool smoothScroll);

  // Streams
  Stream<ReaderSetStateData> get onSetState;
  Stream<String> get onPlayTts;
  Stream<void> get onStopTts;
  Stream<void> get onEndTts;
  Stream<List<ReaderSearchResultData>> get onSetSearchResultList;

  // Cleanup
  Future<void> dispose();
}
```

### ReaderSetStateData

```dart
class ReaderSetStateData {
  final String breadcrumb;           // "Chapter 1 > Section A"
  final String chapterIdentifier;    // "chapter-01.xhtml"
  final String startCfi;             // "epubcfi(...)"
  final int chapterCurrentPage;      // 5
  final int chapterTotalPage;        // 20
  final BookHtmlContent content;     // Full page content
  final bool atStart;                // First page of book?
  final bool atEnd;                  // Last page of book?
}
```

### ReaderSearchResultData

```dart
class ReaderSearchResultData {
  final String destination;     // Page to navigate to
  final String excerpt;         // Text snippet with ellipsis
  final int targetIndex;        // Position in excerpt
}
```

---

## Future Enhancements

### Planned Features

1. **Advanced CFI Support**
   - Text ranges for highlighting
   - Multiple CFI bookmarks per page

2. **Enhanced Search**
   - Regex search
   - Case-insensitive toggle
   - Search history

3. **Performance**
   - Pre-pagination in background
   - Adaptive font loading
   - Parallel page rendering

4. **Annotations**
   - Highlight system with CFI
   - Notes with timestamps
   - Color-coded categories

5. **Accessibility**
   - Enhanced TTS integration
   - High contrast modes
   - Font scaling UI

---

## Contributing

### Code Style

- Follow Dart conventions
- Use meaningful variable names
- Document public APIs with doc comments
- Add unit tests for new features

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature reader_engine

# Commit with descriptive messages
git commit -m "feat: add CFI support for bookmarks"

# Push and open PR
git push origin feature/your-feature
```

### Review Checklist

- [ ] Code follows style guide
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No console warnings
- [ ] Tested on multiple devices

---

## Resources

### Official EPUB Specification
- [EPUB3 Standard](https://www.w3.org/publishing/epub3/)
- [CFI Specification](https://idpf.github.io/epub-cfi/epub-cfi.html)

### Dependencies
- [epubx/epubx.dart](https://pub.dev/packages/epubx) - EPUB parsing
- [webview_flutter](https://pub.dev/packages/webview_flutter) - Web rendering
- [flutter_html](https://pub.dev/packages/flutter_html) - HTML rendering
- [shelf](https://pub.dev/packages/shelf) - HTTP server

### Related Files
- EPUB Book Loader: `epub_book_loader.dart`
- Content Parser: `epub_content_parser.dart`
- Reader UI: `lib/features/reader/presentation/pages/reader_screen.dart`
- Test Samples: `assets/samples/`

---

## License

Part of the NovelGlide project. See LICENSE file for details.

---

**Last Updated:** 2026-02-25  
**Maintained by:** NovelGlide Development Team  
**Status:** Active Development (Phase 5 - Testing & Polish)
