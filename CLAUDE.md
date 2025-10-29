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

## Critical Invariants

1. **At Least One Card Always Exists**: CardManager ensures there is always at least one card in the application. When CardManager is initialized, if no cards exist, it automatically creates an initial search card. This is enforced in the CardManager initializer.

2. **A Card Is Always Selected**: CardManager maintains a `selectedCardId` property that is never nil. When CardManager is initialized, if no card is selected, it automatically selects the first card. When a card is deleted, CardManager automatically selects the next appropriate card (first card created after the deleted card, or the last card if none were created after). This ensures there is always a valid selection.

3. **Selection is Always Persisted**: The currently selected card ID is always saved to UserDefaults and restored on app launch. This ensures the user returns to their last viewed card.

## macOS-Specific Behavior

1. **Sidebar Minimum Width**: On macOS, the sidebar in ContentView has a minimum width of 180 points (ideal: 200) to ensure the "Add Card" button is always visible and not cut off during window resizing.

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

## Planning Discipline

When planning a feature or change:
1. Create a detailed plan and present it for approval
2. Wait for explicit "plan approved" confirmation before implementing
3. **NEVER autonomously diverge from an approved plan**, even if:
   - You think of a better approach
   - The next step seems obvious
   - You want to "just try it quickly"
4. If you discover issues during implementation that require plan changes, **STOP and ask before proceeding**. Present the blocker and propose a solution. This dialogue teaches both parties and strengthens the partnership.
5. Always ask for confirmation before building/testing, even if it seems like the natural next step

**Deviation = Planning Failure.** Autonomous deviations break the planning contract and waste the user's time reviewing unexpected changes. Always defer to the user for approval.

**Exception: Technical Blockers During Implementation.** When implementation reveals a technical blocker (e.g., clipping issues, API limitations), ask the user before fixing it. This conversation reveals insights and makes the team smarter together.

### Concrete Behavior Requirements

When you discover an API doesn't exist or a planned approach is wrong:
1. Stop immediately—do not make changes
2. Output: "I was wrong about X. The actual API/approach is Y. Should I proceed?"
3. Wait for explicit user response before proceeding

When you're about to use a different approach than planned:
1. State the change explicitly
2. Explain why (blocker or discovery)
3. Ask for approval before implementing
4. Do not execute tool calls without approval

If you catch yourself about to diverge without asking:
1. Do not execute the tool call
2. Ask first instead

## Edit Workflow

When making multiple file edits:
1. Show the complete list of affected files upfront
2. For each file, show the exact diffs (old → new) without asking for confirmation on each delta
3. Execute all edits in parallel in a single message
4. Only ask for confirmation if there are ambiguities or potential issues

Use simple old_string → new_string format for clarity, one diff per file.

## Communication Style

- Be direct and terse. Skip pleasantries and affirmations.
- No "Great question!", "You're absolutely right!", or similar noise.
- Only acknowledge if the information is relevant or addresses ambiguity.
- Focus on being useful, not polite.
- When uncertain about facts or making inferences, use "I think..." rather than stating assertions as definite facts.
- Never make assertions without being sure—it's better to acknowledge uncertainty explicitly.
- **Always show line numbers whenever displaying code snippets.** Use the format `line_number→ code_content` to make it easy to reference specific lines.
