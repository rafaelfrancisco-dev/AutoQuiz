# AutoQuiz Modernization Audit

Date: 2026-02-19  
Workspace: `/Users/rafaelfrancisco/Developer/AutoQuiz`  
Scope: iOS/macOS SwiftUI app using SwiftData + Foundation Models; project was started during iOS 26 betas and paused.

## Executive Summary

Primary modernization risks are:

1. SwiftData migration plan exists but is not wired into `ModelContainer` startup.
2. Data model typo (`anwswer`) has become part of persisted contracts and should be migrated carefully.

## Prioritized Findings

## P0 (Fix First)

### 1) Migration plan bypassed at runtime
- Evidence:
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/AutoQuizApp.swift:13`
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Models/Schemas.swift:50`
- Detail:
  - `ItemMigrationPlan` is defined but app startup currently creates a container directly for model types and skips migration path.
- Impact:
  - Schema drift and upgrade risk when adding/changing models.
- Recommendation:
  - Create `ModelContainer` with explicit schema/migration plan:
  - `migrationPlan: ItemMigrationPlan.self`

## P1 (High Value Next)

### 2) `anwswer` field typo should be migrated safely
- Evidence:
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Models/Questions/MultipleChoiceQuestion.swift:20`
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Services/SpacedRepetitionService.swift:31`
- Detail:
  - Misspelled property is used throughout generation/storage.
- Impact:
  - Long-term maintenance and schema clarity issues.
- Recommendation:
  - Plan schema bump with backward-compatible decode mapping, then migrate to `answer`.

### 3) Platform/tooling docs and project settings are inconsistent
- Evidence:
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/README.md:26`
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz.xcodeproj/project.pbxproj:413`
- Detail:
  - README lists iOS 17/macOS 14/Xcode 15 while project settings currently target 26.0 and still declare `SWIFT_VERSION = 5.0`.
- Recommendation:
  - Decide true baseline and supported platforms, then align README and build settings.

### 4) Quiz language option is not wired into generation
- Evidence:
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Models/QuizSettings.swift:48`
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Views/QuizOptionsView.swift:188`
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Logic/Generator.swift:39`
- Detail:
  - UI exposes `useOriginalLanguage`, but generation currently hardcodes English instructions.
- Recommendation:
  - Thread quiz language setting into Generator and locale support checks.

### 5) Content edits do not invalidate all derived artifacts
- Evidence:
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Views/AddContentView.swift:295`
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuiz/Views/SpacedRepetition/SpacedRepetitionView.swift:303`
- Detail:
  - Question arrays are reset after content changes, but historical answers/sessions/cards can remain stale.
- Recommendation:
  - Define explicit invalidation/versioning policy for sessions and spaced repetition cards on content mutation.

### 6) Test coverage is placeholder-only
- Evidence:
  - `/Users/rafaelfrancisco/Developer/AutoQuiz/AutoQuizTests/AutoQuizTests.swift:12`
- Recommendation:
  - Add targeted tests first:
  - migration container boot
  - generator availability/error mapping
  - background cancellation/retry behavior
  - quiz session metric recording

## Current Verification Snapshot

- `swiftlint lint --strict --no-cache` reports high style debt:
  - 762 violations across 42 files (mostly trailing whitespace/line length).
- `xcodebuild build -project AutoQuiz.xcodeproj -scheme AutoQuiz -destination 'platform=macOS' -derivedDataPath /tmp/AutoQuizDerivedData CODE_SIGNING_ALLOWED=NO` succeeded.
- `xcodebuild test -project AutoQuiz.xcodeproj -scheme AutoQuiz -destination 'platform=macOS' -derivedDataPath /tmp/AutoQuizDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:AutoQuizTests` succeeded.

## Recommended Implementation Order

1. Wire migration plan in app startup (`AutoQuizApp` + schema sanity check).
2. Plan and execute `anwswer` -> `answer` migration.
3. Align project settings/README and decide platform scope.
4. Tackle lint cleanup with an automated formatting pass + lint baseline reduction.

## Open Decisions For Next Session

1. Keep iOS/macOS 26+ only, or add fallback for older OS versions?
2. Keep macOS/visionOS targets, or narrow to iOS/iPadOS?
3. On content edits, should analytics/repetition history be preserved, versioned, or reset?
4. Preferred language strategy: document language vs app locale vs explicit selector?

## Sources

- Apple Foundation Models docs: https://developer.apple.com/documentation/foundationmodels
- `SystemLanguageModel` docs: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
- `LanguageModelSession` docs: https://developer.apple.com/documentation/foundationmodels/languagemodelsession
- Prompting an on-device model: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model
- Context window technical note (TN3193): https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window
- Code along session page: https://developer.apple.com/events/resources/code-along-205/

Also validated against local Xcode 26.2 SDK interfaces:
- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/FoundationModels.framework/Modules/FoundationModels.swiftmodule/arm64e-apple-ios.swiftinterface`
- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/SwiftData.framework/Modules/SwiftData.swiftmodule/arm64e-apple-ios.swiftinterface`
