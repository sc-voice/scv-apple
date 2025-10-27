# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SC-Voice is a macOS/iOS SwiftUI application for searching and viewing Buddhist suttas (scriptures). It uses SwiftData for persistence and provides a card-based interface where users can create multiple search and sutta viewer cards.

## Build and Test Commands

### Building
```bash
# Build the project
xcodebuild -scheme scv -configuration Debug build

# Build for release
xcodebuild -scheme scv -configuration Release build
```

### Testing
```bash
# Run all tests
xcodebuild test -scheme scv -testPlan scv.xctestplan

# Run unit tests only
xcodebuild test -scheme scv -only-testing:scvTests

# Run UI tests only
xcodebuild test -scheme scv -only-testing:scvUITests

# Run a specific test class
xcodebuild test -scheme scv -only-testing:scvTests/CardTests
```

### Opening in Xcode
```bash
open scv.xcodeproj
```

## Architecture

### Core Data Model

**Card (SwiftData Model)**: The central data model that represents either a search card or a sutta viewer card. Uses SwiftData for persistence with an in-memory container for the app.

- `CardType` enum: `.search` or `.sutta`
- Each card has a unique `typeId` per card type (search cards and sutta cards have separate ID sequences)
- `CardManager`: Observable class that manages CRUD operations for cards via SwiftData's ModelContext

### Views

**ContentView**: Main container with NavigationSplitView architecture
- Left sidebar: List of all cards (managed by CardManager)
- Detail pane: Shows either SearchView or SuttaView based on selected card
- Handles card selection, deletion, and keyboard shortcuts (Delete/Backspace to remove cards)
- Persists selected card ID to UserDefaults

**SearchView**: Search interface for finding suttas by keywords
- Performs API calls to `https://sc-voice.github.io/api/scv/search/{query}`
- Caches search results in Card's `searchResults` property
- Displays matched segments grouped by document
- Uses SearchResponse model for parsing API responses

**SuttaView**: Viewer for displaying full sutta content
- Loads sutta by reference (e.g., "mn1", "sn1.1")
- Currently reuses the search API endpoint (TODO: needs dedicated sutta API)
- Displays sutta metadata (title, blurb, stats) and all segments
- Shows both Pali and English translations side by side

### Data Models

**SearchResponse**: Codable model for API responses
- Contains `mlDocs` array of MLDocument objects
- Each MLDocument has `segMap` dictionary mapping segment IDs to Segment objects
- Includes DocumentStats for metadata (segment counts, reading time)
- Has error handling fields (`searchError`, `searchSuggestion`)

**Search**: Abstract class with factory methods
- `MockSearch` subclass loads data from `scv/Resources/MockResponse.json`
- Currently only "root of suffering" query returns mock data; other queries return "not supported" error

### Localization

Localization files are in `scv/Resources/Localization/` with separate `.lproj` directories for each supported language.

Use the `.localized` extension method on String (defined in LocalizationHelper.swift) to access localized strings.

**Testing**: Ensure that each localization file in `scv/Resources/Localization/` has corresponding test coverage. The `testCloseCardAccessibilityLabelInDifferentLanguages` test in CardTests.swift validates all supported languages.

## Key Design Patterns

1. **Card-based Architecture**: All content (searches and suttas) are represented as persistent Card objects. Cards alternate between search and sutta types when created.

2. **Observable Pattern**: CardManager uses @Observable macro to automatically notify SwiftUI views of changes to the card collection.

3. **SwiftData Integration**: App uses SwiftData for persistence with a ModelContainer configured in scvApp.swift. The schema includes only the Card model.

4. **Focus Management**: ContentView tracks focused card with @FocusState for keyboard navigation and deletion.

5. **Result Caching**: Search results are cached as Data in the Card model to avoid redundant API calls when switching between cards.

## Testing

The project uses Swift Testing framework (not XCTest):
- `scvTests/`: Unit tests for models (CardTests, SearchResponseTests)
- `scvUITests/`: UI tests for views (SearchView, SuttaView tests)
- Tests use `@Test` macro and `#expect()` for assertions
- In-memory ModelContainer used for testing SwiftData models

## API Integration

Current API endpoint: `https://sc-voice.github.io/api/scv/search/{query}`
- Used for both search queries and sutta lookups
- Returns SearchResponse JSON with matched segments
- TODO: The SuttaView should use a dedicated sutta API endpoint instead of the search endpoint
