# AutoQuiz

AutoQuiz is an intelligent SwiftUI-based application that generates interactive quiz questions from your documents and lets you ask document-grounded questions using Apple's FoundationModels framework. Transform your PDFs and text files into engaging quizzes and searchable study material for enhanced learning and knowledge retention.

## Features

- **AI-Powered Question Generation**: Leverages Apple's FoundationModels to create intelligent multiple choice and true/false questions
- **Document Q&A**: Ask grounded questions about a document and save revision-aware answers per document version
- **Multi-Format Document Support**: Import and process PDF and text documents
- **Cross-Platform**: Native support for iPhone, iPad, macOS, and visionOS with platform-appropriate navigation and modal presentation
- **Smart Quiz Management**: Configurable quiz settings with unlimited question mode
- **Performance Analytics**: Track your quiz performance with detailed metrics and accuracy trends
- **Revision-Aware Persistence**: Wax-backed local storage for documents, quiz history, spaced repetition, and document Q&A
- **Offline Operation**: Works entirely offline without requiring internet connectivity

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **Wax**: Local-first persistence and text indexing
- **FoundationModels**: Apple's machine learning framework for AI generation
- **PDFKit**: PDF document processing (macOS/iOS)
- **UniformTypeIdentifiers**: File type management
- **OSLog**: Advanced logging and debugging

## Requirements

- **macOS**: 26.0+
- **iOS**: 26.0+
- **Xcode**: 26.0+
- **Swift**: Swift toolchain in Xcode 26 (project currently uses Swift language mode 5.0)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/rafaelfrancisco-dev/AutoQuiz.git
   cd AutoQuiz
   ```

2. Open in Xcode:
   ```bash
   open AutoQuiz.xcodeproj
   ```

3. Select your target platform (macOS, iPhone/iPad, or visionOS) and run the project

## Usage

### Getting Started

1. **Launch AutoQuiz** on your device
2. **Import Documents**: Click the "+" button to add PDF or text files
3. **Generate Questions**: The app automatically creates quiz questions from your content
4. **Ask Document Questions**: Open a document and ask grounded questions about its current content
5. **Take Quizzes**: Navigate through questions with multiple choice or true/false formats
6. **Track Progress**: View analytics to monitor your learning progress

### Quiz Settings

- **Question Limit**: Set a specific number of questions (default: 10)
- **Unlimited Mode**: Enable for continuous question generation
- **Question Types**: Choose between multiple choice, true/false, or mixed formats
- **Shuffle Options**: Randomize question and answer order

### Document Management

- **Supported Formats**: PDF, TXT, and other text-based documents
- **Content Limits**: Documents are processed with a 3,800 character limit for optimal AI generation
- **Auto-Titles**: AI generates descriptive titles for imported documents
- **Saved Document Answers**: Document Q&A is stored per content revision so older answers remain available after edits

## Architecture

AutoQuiz follows a clean MVVM architecture with the following key components:

### Core Models
- **Item**: Stores document content, revisions, and generated questions
- **Question Types**: `MultipleChoiceQuestion` and `TrueFalseQuestion` with `@Generable` annotation
- **DocumentQuestionAnswer**: Stores saved document Q&A pairs per content revision
- **Analytics**: `QuizSession` and `PerformanceMetrics` for tracking

### ViewModels
- **DocumentViewModel**: Central coordinator managing quiz state and generation
- Modular extensions for different concerns (Navigation, Quiz Session, Question Answering)

### Services
- **Generator**: Handles AI-powered question, title, and document-answer generation
- **AnalyticsService**: Manages performance tracking and metrics
- **FileHandler**: Document processing and content extraction
- **AutoQuizStore / AppStore**: Persist and load documents, quiz artifacts, and saved Q&A

### Data Flow
1. Document import through platform-specific file pickers
2. Content extraction and storage in the local Wax store
3. AI-powered question generation and document answering using FoundationModels
4. Interactive quiz presentation with progress tracking
5. Revision-aware persistence and historical analytics management

## Development

### Building

```bash
# Debug build
xcodebuild -scheme AutoQuiz -configuration Debug

# Release build
xcodebuild -scheme AutoQuiz -configuration Release
```

### Testing

```bash
# Run the full macOS test suite
xcodebuild test -scheme AutoQuiz -destination 'platform=macOS'

# Run tests on iOS Simulator
xcodebuild test -scheme AutoQuiz -destination 'platform=iOS Simulator,name=iPhone 15'
```

UI coverage includes seeded macOS UI tests for split-view launch, document selection, and document-level modal presentation flows.

### Persistence

The app uses a Wax-backed local store in Application Support for documents, answered questions, quiz sessions, spaced repetition cards, and saved document Q&A.

## Platform Differences

### iPhone and iPad
- Uses `UIDocumentPickerViewController` for file selection
- Touch-optimized navigation and toolbar placement
- Adaptive layouts for compact and regular-width presentations

### macOS
- Uses `NSOpenPanel` for native file picker experience
- Desktop-optimized layouts with proper window management
- Keyboard shortcuts and menu integration

### visionOS
- Uses the iOS document picker path for file import
- Preserves native SwiftUI split-view, toolbar, and sheet behavior for windowed presentation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow SwiftUI and iOS/macOS best practices
- Maintain compatibility with minimum OS versions
- Add appropriate unit tests for new features
- Update documentation for significant changes
- Use SwiftData migration patterns for model changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Apple's FoundationModels framework
- Utilizes SwiftUI for cross-platform compatibility
- Inspired by the need for intelligent document-based learning tools

---

**AutoQuiz** - Transform your documents into interactive learning experiences with the power of AI.
