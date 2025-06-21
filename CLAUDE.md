# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
- `xcodebuild -scheme AutoQuiz -configuration Debug` - Build the app in debug mode
- `xcodebuild -scheme AutoQuiz -configuration Release` - Build the app in release mode
- Open `AutoQuiz.xcodeproj` in Xcode to run the app directly

### Testing
- `xcodebuild test -scheme AutoQuiz -destination 'platform=macOS'` - Run unit tests
- `xcodebuild test -scheme AutoQuiz -destination 'platform=iOS Simulator,name=iPhone 15'` - Run tests on iOS simulator

## Architecture Overview

AutoQuiz is a SwiftUI-based app that generates quiz questions from documents using Apple's FoundationModels framework. The app supports both macOS and iOS.

### Core Architecture
- **SwiftData** for data persistence with `Item` model storing document content and generated questions
- **FoundationModels** integration for AI-powered question generation using `@Generable` protocol
- **MVVM pattern** with `DocumentViewModel` coordinating between models and views
- **Cross-platform** support with conditional compilation for iOS/macOS differences

### Key Components
- `Item` (SwiftData model): Stores document content, timestamp, title, and generated questions
- `Question` (Codable struct): Represents multiple choice questions with `@Generable` annotation
- `Generator`: Handles AI generation of questions and titles from document content
- `DocumentViewModel`: Observable view model managing quiz state and generation
- `GenerativeView`: Wrapper providing LanguageModelSession to child views

### Data Flow
1. User imports documents (PDF/text) through platform-specific file pickers
2. Document content is stored as `Item` in SwiftData
3. `Generator` uses FoundationModels to create questions from content (limited to 3800 chars)
4. Generated questions are displayed in quiz format with navigation controls
5. User can navigate between questions and track answers

### Platform Differences
- iOS: Uses `UIDocumentPickerViewController` for file selection
- macOS: Uses `NSOpenPanel` for file selection
- Conditional toolbar placement and navigation controls per platform

## SwiftData Migration Strategy

### Current Schema Versions
- **SchemaV1** (Version 1.0.0): Original schema with `ItemV1` including `totalPoints` field
- **SchemaV2** (Version 2.0.0): Current schema with `ItemV2` (removed `totalPoints`) and `AnsweredQuestionV1`

### Migration Setup
- Migration plan: `ItemMigrationPlan` handles V1→V2 lightweight migration
- Typealiases: `Item = ItemV2`, `AnsweredQuestion = AnsweredQuestionV1`
- Model files: `ItemV1.swift`, `ItemV2.swift`, `AnsweredQuestionV1.swift`
- All schema definitions in `Models/Schemas.swift`

### Important Migration Notes
- Never change existing schema version identifiers once released
- Create new schema versions for any model changes
- Use lightweight migrations for simple field additions/removals
- Use custom migrations for complex transformations
- Fresh app installations start with SchemaV2

## Quiz Features

### Auto-End Quiz
- **Location**: `DocumentViewModel+QuestionAnswering.swift:handleAutoAdvanceAfterAnswer()`
- **Behavior**: Automatically ends quiz when reaching `maxQuestions` limit in non-unlimited mode
- **Trigger**: After answering the final question (with 1-second delay)
- **Condition**: `!currentQuizSettings.isUnlimitedQuestions && currentSessionAnsweredQuestions.count >= currentQuizSettings.maxQuestions`

### Quiz Settings
- **Default**: 10 questions, multiple choice, shuffle enabled
- **Unlimited mode**: Set via `QuizSettings.setUnlimitedQuestions()` (maxQuestions = Int.max)
- **Types**: Multiple choice and true/false questions
- **Session management**: Questions stored in `currentSessionQuestions` array

## iOS 26 / SwiftUI Features

### New Features Available
References:
- [What's new in SwiftUI for iOS 26](https://www.hackingwithswift.com/articles/278/whats-new-in-swiftui-for-ios-26)
- [Apple Documentation: Applying Liquid Glass to Custom Views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

#### Major New Components
- **WebView**: Native web content embedding capability
- **TextView**: Rich text editing with AttributedString support

#### UI and Interaction Improvements
- **List section index labels**: Better navigation for long lists
- **Label icons with fixed width**: Consistent icon alignment
- **Automatic scene-appropriate padding**: Adaptive spacing
- **@Animatable macro**: Simplified custom view/modifier animations
- **Enhanced openURL**: In-app browser support

#### Liquid Glass UI Enhancements
- **TabView minimization on scroll**: Dynamic tab bar behavior
- **TabView accessories**: Additional customization options
- **Custom scroll edge effects**: Enhanced ScrollView/List transitions
- **Custom section spacing**: Fine-grained list control
- **Toolbar spacing options**: Better toolbar customization
- **Navigation subtitle support**: Hierarchical navigation titles
- **Custom view liquid glass effects**: Apply glass material effects to custom components (see Apple documentation for implementation details)

#### SF Symbols Updates
- **"Draw on" animations**: New checkbox and UI element animations

#### Considerations
- Wait for beta 4-5 before adopting new features for API stability
- Still missing: Camera import, QR scanning, AsyncImageView cache control, iCloud @AppStorage sync

## Code Conventions

### Model Naming
- Use versioned model names (e.g., `ItemV1`, `ItemV2`) for migration compatibility
- Keep original model files when creating new versions
- Update typealiases to point to latest versions

### Error Handling
- Use `fatalError` for unrecoverable SwiftData container creation failures
- Log migration steps using `Logger.database` for debugging
- Handle build errors by checking model compatibility and imports