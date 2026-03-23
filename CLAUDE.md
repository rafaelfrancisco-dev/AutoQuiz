# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Open project
open AutoQuiz.xcodeproj

# Debug build (macOS)
xcodebuild -scheme AutoQuiz -configuration Debug

# Run full test suite on macOS
xcodebuild test -scheme AutoQuiz -destination 'platform=macOS'

# Run tests on iOS Simulator
xcodebuild test -scheme AutoQuiz -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a single test (Swift Testing)
xcodebuild test -scheme AutoQuiz -destination 'platform=macOS' -only-testing:AutoQuizTests/GeneratorErrorMappingTests/availabilityIsMappedToGeneratorErrors
```

Requirements: macOS 26+, iOS 26+, Xcode 26+. The project uses Swift language mode 5.0.

## Architecture

AutoQuiz is a cross-platform SwiftUI app (iOS, macOS, visionOS) that generates quiz questions from imported documents using Apple's FoundationModels (on-device AI). It requires Apple Intelligence to be enabled.

### Persistence: Wax Store

The app does **not** use SwiftData or CoreData. Persistence is handled by the `Wax` framework (a local-first append-log store stored at `Application Support/AutoQuiz/autoquiz.mv2s`).

- `AutoQuizStore` (actor) — low-level Wax wrapper. Maintains in-memory dictionaries (`itemsByID`, `sessionsByID`, etc.) mirroring the on-disk state. Every entity write goes through `persist()`, which writes a `WaxEntityEnvelope` containing the JSON-encoded payload, then calls `wax.supersede()` to mark the old frame as replaced.
- `AppStore` (@Observable, @MainActor) — app-facing store. Owns an `AutoQuizStore` and exposes async `save*`/`delete*` methods. Bootstraps on app launch via `.task`. UI tests inject fixture data via `loadFixture()` triggered by the `UITEST_SAMPLE_DATA` launch argument. Exposes `isIndexingChunks: Bool` which reflects background chunk indexing state.
- Entity types: `Item`, `AnsweredQuestion`, `QuizSession`, `SpacedRepetitionCard`, `DocumentQuestionAnswer` — all plain `Codable` classes/structs, not SwiftData models.

#### Vector Search & Chunk Indexing

Document content is split into 2,000-char chunks and embedded via `NLEmbeddingProvider` for semantic Q&A search. Key behaviors:

- **Language-aware embeddings**: `NLEmbeddingProvider` detects each chunk's language via `NLLanguageRecognizer.dominantLanguage(for:)` and calls `NLEmbedding.sentenceEmbedding(for: detectedLanguage)`, falling back to `.english` only if the detected language has no sentence embedding. The identity key is `"sentence-multilingual"`.
- **Language persistence**: The embedding language used per document is stored in chunk frame metadata under `WaxMetadataKeys.chunkEmbeddingLanguage` (`aq.chunk.embeddingLanguage`) and restored into `embeddingLanguageByDocumentID` on `loadFromDisk()`. Queries always use the same language model as the indexed chunks.
- **Fire-and-forget indexing**: `upsertItem()` spawns chunk indexing in a detached `Task` so the actor is never blocked. `AutoQuizStore.setOnIndexingStateChanged(_:)` registers a `@Sendable` callback that fires `true` when indexing starts and `false` when it finishes (including early returns). `AppStore` registers this callback in both `bootstrap()` and `loadFixture()`, hopping to `@MainActor` to update `isIndexingChunks`.
- **Changing the embedding identity invalidates stored chunks.** Chunks indexed under the old identity (`"sentence-en"`) will not be re-queried; they are silently replaced the next time the document's `contentRevision` changes.

### AI Generation: Generator + FoundationModels

`Generator` wraps `LanguageModelSession` from FoundationModels. Key behaviors:
- Uses `@Generable` structs (`MultipleChoiceQuestionBatch`, `TrueFalseQuestionBatch`, `DocumentAnswerPayload`) for structured output.
- Language resolution: detects document language via `NLLanguageRecognizer`, then verifies against `SystemLanguageModel.default.supportedLanguages`. Falls back to user selection if unresolvable.
- Content is chunked to 3,500 chars for question generation; document Q&A uses ranked keyword-scored chunks (max 3 × 2,500 chars).
- In test environments (`XCTestConfigurationFilePath` env var present), `currentAvailabilityIssue()` always returns `nil` to bypass device eligibility checks.

### ViewModel: DocumentViewModel

`DocumentViewModel` (@Observable, @MainActor) is the central coordinator per document. It is split across extensions:
- `DocumentViewModel.swift` — core state and `persist*` fire-and-forget helpers
- `+Navigation.swift` — question index/type navigation, `canNavigateToNext`
- `+QuizSession.swift` — session lifecycle, answer recording, scoring
- `+BackgroundGeneration.swift` — background pre-generation of questions
- `+WaitingState.swift` — inter-question delay logic
- `+DocumentQuestions.swift` — document Q&A flow
- `+QuestionAnswering.swift` — answer submission and correctness evaluation

The `documentAnswerProvider` closure is injected at init, allowing tests to stub AI calls without hitting FoundationModels.

### Views

- `ContentView` — `NavigationSplitView` sidebar (document list) + detail. Platform-specific file pickers: `NSOpenPanel` on macOS, `UIDocumentPickerViewController` (wrapped as `DocumentPicker`) on iOS/visionOS.
- `DocumentView` — per-document detail with tab-style navigation between quiz, analytics, spaced repetition, and document Q&A. The `statusSection` computed view shows prioritised status cards: generation issues first, then an "Indexing Document" card while `appStore.isIndexingChunks` is true, then the "Preparing Questions" fallback.
- Shared UI primitives in `Views/Shared/AppUI.swift`: `AppBadge`, `AppEmptyState`, `AppCardModifier`, `AppDashboardModalContainer`, `QuizActionButtonStyle`, `AdaptiveMetricGrid`.
- `AppDashboardModalContainer` renders as a plain `ScrollView` with a custom header on macOS, and as a `NavigationStack` sheet on iOS/visionOS.

### Revision Tracking

`Item.contentRevision` (Int) increments whenever document content changes (policy in `ContentRevisionPolicy`). `QuizSession`, `SpacedRepetitionCard`, and `DocumentQuestionAnswer` each store a `sourceContentRevision` so historical data from old revisions remains queryable and is never silently overwritten.

### Logging

Named `Logger` categories are defined in `Utilities/OSLog+Extensions.swift`: `database`, `viewModel`, `generation`, `quiz`, `ui`, `error`.

## Testing Patterns

Tests use Swift Testing (`import Testing`, `@Test`, `#expect`). `DocumentViewModel` tests inject a stub `documentAnswerProvider` closure. There are no mock stores — tests exercise real logic directly against in-memory state.

UI tests pass `UITEST_SAMPLE_DATA` as a launch argument; the app bootstraps from `PreviewData` fixtures into a temporary Wax store instead of the real one.
