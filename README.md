# AutoQuiz

AutoQuiz is an intelligent SwiftUI-based application that generates interactive quiz questions from your documents using Apple's FoundationModels framework. Transform your PDFs and text files into engaging quizzes for enhanced learning and knowledge retention.

## Features

- **AI-Powered Question Generation**: Leverages Apple's FoundationModels to create intelligent multiple choice and true/false questions
- **Multi-Format Document Support**: Import and process PDF and text documents
- **Cross-Platform**: Native support for both macOS and iOS with platform-specific optimizations
- **Smart Quiz Management**: Configurable quiz settings with unlimited question mode
- **Performance Analytics**: Track your quiz performance with detailed metrics and accuracy trends
- **Data Persistence**: Robust SwiftData integration with migration support
- **Offline Operation**: Works entirely offline without requiring internet connectivity

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Core Data successor for data persistence
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

3. Select your target platform (macOS or iOS) and run the project

## Usage

### Getting Started

1. **Launch AutoQuiz** on your device
2. **Import Documents**: Click the "+" button to add PDF or text files
3. **Generate Questions**: The app automatically creates quiz questions from your content
4. **Take Quizzes**: Navigate through questions with multiple choice or true/false formats
5. **Track Progress**: View analytics to monitor your learning progress

### Quiz Settings

- **Question Limit**: Set a specific number of questions (default: 10)
- **Unlimited Mode**: Enable for continuous question generation
- **Question Types**: Choose between multiple choice, true/false, or mixed formats
- **Shuffle Options**: Randomize question and answer order

### Document Management

- **Supported Formats**: PDF, TXT, and other text-based documents
- **Content Limits**: Documents are processed with a 3,800 character limit for optimal AI generation
- **Auto-Titles**: AI generates descriptive titles for imported documents

## Architecture

AutoQuiz follows a clean MVVM architecture with the following key components:

### Core Models
- **Item (SwiftData)**: Stores document content and generated questions
- **Question Types**: `MultipleChoiceQuestion` and `TrueFalseQuestion` with `@Generable` annotation
- **Analytics**: `QuizSession` and `PerformanceMetrics` for tracking

### ViewModels
- **DocumentViewModel**: Central coordinator managing quiz state and generation
- Modular extensions for different concerns (Navigation, Quiz Session, Question Answering)

### Services
- **Generator**: Handles AI-powered question and title generation
- **AnalyticsService**: Manages performance tracking and metrics
- **FileHandler**: Document processing and content extraction

### Data Flow
1. Document import through platform-specific file pickers
2. Content extraction and storage in SwiftData
3. AI-powered question generation using FoundationModels
4. Interactive quiz presentation with progress tracking
5. Performance analytics and historical data management

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
# Run unit tests on macOS
xcodebuild test -scheme AutoQuiz -destination 'platform=macOS'

# Run tests on iOS Simulator
xcodebuild test -scheme AutoQuiz -destination 'platform=iOS Simulator,name=iPhone 15'
```

### SwiftData Migration

The app uses a versioned schema approach:
- **SchemaV1**: Original schema with `totalPoints` field
- **SchemaV2**: Current schema with improved analytics structure

Migration is handled automatically through `ItemMigrationPlan` for seamless updates.

## Platform Differences

### iOS
- Uses `UIDocumentPickerViewController` for file selection
- Touch-optimized navigation and toolbar placement
- Mobile-specific UI adaptations

### macOS
- Uses `NSOpenPanel` for native file picker experience
- Desktop-optimized layouts with proper window management
- Keyboard shortcuts and menu integration

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