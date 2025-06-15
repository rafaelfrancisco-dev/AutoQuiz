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