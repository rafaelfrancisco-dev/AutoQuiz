//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import OSLog
import SwiftUI

private enum DocumentModalDestination: String, Identifiable {
    case quizOptions
    case addContent
    case history
    case analytics
    case spacedRepetition
    case documentQuestions

    var id: String { rawValue }
}

private enum DocumentSheetDestination: Identifiable, Equatable {
    case modal(DocumentModalDestination)
    case languageSelection

    var id: String {
        switch self {
        case .modal(let destination):
            return destination.id
        case .languageSelection:
            return "languageSelection"
        }
    }
}

struct GenerationLoadingIndicator: View {
    let message: String
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(scale)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: .capsule)
    }
}

struct DocumentView: View {
    @Environment(AppStore.self) private var appStore

    @State private var viewModel: DocumentViewModel
    @State private var presentedSheet: DocumentSheetDestination?
    @State private var selectedFallbackLanguageIdentifier: String?

    init(item: Item) {
        _viewModel = State(initialValue: DocumentViewModel(item: item))
    }

    init(viewModel: DocumentViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            Group {
                if viewModel.hasStartedQuiz {
                    quizContent
                } else {
                    startContent
                }
            }
            .padding()
            .appContentWidth()
        }
        .background(.background)
        .navigationTitle(viewModel.item.title ?? "Document")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                documentActionsMenu
            }
        }
        .sheet(item: presentedSheetBinding) { destination in
            switch destination {
            case .modal(let route):
                modalContent(for: route)
            case .languageSelection:
                fallbackLanguageSheet
            }
        }
        .task {
            await performInitialLoad()
        }
        .onChange(of: viewModel.isShowingLanguageSelection) { _, isPresented in
            if isPresented {
                selectedFallbackLanguageIdentifier = viewModel.pendingSupportedLanguages.first?.persistedIdentifier
                presentedSheet = .languageSelection
            }
        }
        .onAppear {
            viewModel.appStore = appStore
        }
        .onDisappear {
            viewModel.stopBackgroundGeneration()
        }
        .alert("Quiz Results", isPresented: resultsBinding) {
            Button("Start New Quiz") {
                viewModel.resetQuiz()
            }

            Button("Cancel", role: .cancel) {
                viewModel.showingResults = false
            }
        } message: {
            Text(
                "Questions answered: \(viewModel.quizResults.totalQuestions)\n" +
                "Correct answers: \(viewModel.quizResults.correctAnswers)\n" +
                "Points earned: \(viewModel.quizResults.totalPoints)"
            )
        }
    }

    private var presentedSheetBinding: Binding<DocumentSheetDestination?> {
        Binding(
            get: { presentedSheet },
            set: { newValue in
                if newValue == nil, presentedSheet == .languageSelection {
                    viewModel.isShowingLanguageSelection = false
                }
                presentedSheet = newValue
            }
        )
    }

    private var resultsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showingResults },
            set: { viewModel.showingResults = $0 }
        )
    }

    private var documentActionsMenu: some View {
        Menu {
            Button("Quiz Options") {
                present(.quizOptions)
            }

            Button("Add Content") {
                present(.addContent)
            }

            Button("Question History") {
                present(.history)
            }
        } label: {
            Label("Document Actions", systemImage: "ellipsis.circle")
        }
        .accessibilityIdentifier("document-actions-menu")
    }

    @ViewBuilder
    private func modalContent(for destination: DocumentModalDestination) -> some View {
        switch destination {
        case .quizOptions:
            QuizOptionsView { settings in
                presentedSheet = nil
                withAnimation {
                    viewModel.startQuiz(with: settings)
                }
            }
        case .addContent:
            AddContentView(item: viewModel.item)
        case .history:
            HistoricalQuestionsView(item: viewModel.item)
        case .analytics:
            AnalyticsView(document: viewModel.item)
        case .spacedRepetition:
            SpacedRepetitionView(document: viewModel.item)
        case .documentQuestions:
            DocumentQuestionAnsweringView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var fallbackLanguageSheet: some View {
        Group {
            #if os(macOS)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppMacModalHeader(
                        title: "Choose Language",
                        subtitle: "Select a supported language so question generation can continue."
                    ) {
                        Button("Cancel") {
                            viewModel.isShowingLanguageSelection = false
                        }
                    }

                    AppMacFormSection(title: "Supported Languages") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.pendingSupportedLanguages, id: \.persistedIdentifier) { language in
                                Button {
                                    selectedFallbackLanguageIdentifier = language.persistedIdentifier
                                } label: {
                                    HStack {
                                        Text(localizedLanguageName(for: language))
                                        Spacer()
                                        if selectedFallbackLanguageIdentifier == language.persistedIdentifier {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.primary)
                            }
                        }
                    }

                    HStack {
                        Spacer()

                        Button("Continue") {
                            guard let selectedFallbackLanguageIdentifier else { return }
                            viewModel.applyFallbackLanguage(Locale.Language(identifier: selectedFallbackLanguageIdentifier))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedFallbackLanguageIdentifier == nil)
                    }
                }
                .padding(24)
                .frame(maxWidth: 460, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .macModalSize(.utilityCompact)
            #else
            NavigationStack {
                List {
                    ForEach(viewModel.pendingSupportedLanguages, id: \.persistedIdentifier) { language in
                        Button {
                            selectedFallbackLanguageIdentifier = language.persistedIdentifier
                        } label: {
                            HStack {
                                Text(localizedLanguageName(for: language))
                                Spacer()
                                if selectedFallbackLanguageIdentifier == language.persistedIdentifier {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .navigationTitle("Choose Language")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.isShowingLanguageSelection = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Continue") {
                            guard let selectedFallbackLanguageIdentifier else { return }
                            viewModel.applyFallbackLanguage(Locale.Language(identifier: selectedFallbackLanguageIdentifier))
                        }
                        .disabled(selectedFallbackLanguageIdentifier == nil)
                    }
                }
            }
            .macModalSize(.utilityCompact)
            #endif
        }
        .onAppear {
            if selectedFallbackLanguageIdentifier == nil {
                selectedFallbackLanguageIdentifier = viewModel.pendingSupportedLanguages.first?.persistedIdentifier
            }
        }
    }

    private var startContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            DocumentSummaryCard(
                item: viewModel.item,
                totalQuestionCount: totalQuestionCount,
                wordCount: wordCount,
                isGenerating: viewModel.isGenerating
            )

            DocumentStartActions(
                isGenerating: viewModel.isGenerating,
                onStartQuiz: { present(.quizOptions) },
                onAskDocument: { present(.documentQuestions) },
                onAnalytics: { present(.analytics) },
                onSpacedRepetition: { present(.spacedRepetition) }
            )

            statusSection
        }
        .accessibilityIdentifier("document-start-screen")
    }

    @ViewBuilder
    private var statusSection: some View {
        if let generationIssueMessage = viewModel.generationIssueMessage {
            DocumentStatusCard(
                title: "Generation Issue",
                message: generationIssueMessage,
                tone: .warning
            )
        } else if !viewModel.isGenerating && !hasQuestionsForType(viewModel.selectedQuestionType) {
            DocumentStatusCard(
                title: "Preparing Questions",
                message: "Questions are being generated in the background. You can still add content or review analytics.",
                tone: .info
            )
        }
    }

    private var quizContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            QuizHeaderCard(
                currentIndex: viewModel.currentQuestionIndex,
                totalQuestions: viewModel.currentQuizSettings.isUnlimitedQuestions
                    ? viewModel.currentSessionQuestions.count
                    : viewModel.currentQuizSettings.maxQuestions,
                isUnlimited: viewModel.currentQuizSettings.isUnlimitedQuestions,
                currentPoints: viewModel.currentPoints,
                progress: quizProgress,
                onEndQuiz: { viewModel.endQuiz() }
            )

            currentQuestionView

            if viewModel.shouldShowWaitingIndicator {
                GenerationLoadingIndicator(
                    message: "Generating next question...",
                    scale: 0.8
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }

            QuizNavigationFooter(
                canGoBack: viewModel.currentQuestionIndex > 0,
                canGoForward: viewModel.canNavigateToNext,
                onPrevious: {
                    withAnimation {
                        viewModel.currentQuestionIndex -= 1
                    }
                },
                onNext: {
                    withAnimation {
                        viewModel.currentQuestionIndex += 1
                    }
                }
            )
        }
        .accessibilityIdentifier("document-quiz-screen")
    }

    @ViewBuilder
    private var currentQuestionView: some View {
        if let currentSessionQuestion = viewModel.getCurrentSessionQuestion() {
            switch currentSessionQuestion {
            case .multipleChoice(let question, _):
                MultipleQuestionView(
                    question: question,
                    previousAnswer: viewModel.getPreviousAnswer(for: question)
                ) { isValid, userAnswer in
                    viewModel.answeredQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                }
                .id("multiple-\(viewModel.currentQuestionIndex)")
            case .trueFalse(let question, _):
                TrueFalseQuestionView(
                    question: question,
                    previousAnswer: viewModel.getPreviousAnswer(for: question)
                ) { isValid, userAnswer in
                    viewModel.answeredTrueFalseQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                }
                .id("truefalse-\(viewModel.currentQuestionIndex)")
            case .spacedRepetition:
                DocumentStatusCard(
                    title: "Unsupported Quiz State",
                    message: "Spaced repetition cards should not appear in the standard quiz flow.",
                    tone: .danger
                )
            }
        } else {
            DocumentStatusCard(
                title: "No Active Question",
                message: "This quiz is waiting for the next generated question.",
                tone: .info
            )
        }
    }

    private var quizProgress: Double {
        guard !viewModel.currentQuizSettings.isUnlimitedQuestions else {
            guard !viewModel.currentSessionQuestions.isEmpty else { return 0 }
            return Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.currentSessionQuestions.count)
        }

        return Double(viewModel.currentQuestionIndex + 1) / Double(max(viewModel.currentQuizSettings.maxQuestions, 1))
    }

    private func performInitialLoad() async {
        if viewModel.item.title == nil {
            await generateTitleIfNeeded()
        }

        viewModel.startBackgroundGeneration()
    }

    private func generateTitleIfNeeded() async {
        withAnimation {
            viewModel.isGenerating = true
        }

        defer {
            withAnimation {
                viewModel.isGenerating = false
            }
        }

        do {
            let title = try await viewModel.generator.generateTitle()
            withAnimation {
                viewModel.item.title = title
                viewModel.generationIssue = nil
            }
            viewModel.persistItemChanges()
            viewModel.persistDocumentMetadata()
        } catch let error as GeneratorError {
            viewModel.generationIssue = error
            Logger.error.error("Failed to generate title: \(error.userFacingMessage)")
        } catch {
            Logger.error.error("Failed to generate title: \(error.localizedDescription)")
        }
    }

    private func present(_ destination: DocumentModalDestination) {
        presentedSheet = .modal(destination)
    }

    private func localizedLanguageName(for language: Locale.Language) -> String {
        Locale.current.localizedString(forLanguageCode: language.displayIdentifier) ?? language.persistedIdentifier
    }

    private func hasQuestionsForType(_ type: Question) -> Bool {
        switch type {
        case .multipleChoice:
            return !viewModel.item.questions.isEmpty
        case .trueFalse:
            return !(viewModel.item.trueFalseQuestions ?? []).isEmpty
        case .spacedRepetition:
            return true
        }
    }

    private var wordCount: Int {
        viewModel.item.content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    private var totalQuestionCount: Int {
        viewModel.item.questions.count + (viewModel.item.trueFalseQuestions?.count ?? 0)
    }
}

private struct DocumentSummaryCard: View {
    let item: Item
    let totalQuestionCount: Int
    let wordCount: Int
    let isGenerating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title ?? "Untitled Document")
                        .font(.title2.weight(.semibold))

                    Text(item.timestamp, format: .dateTime.month().day().year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isGenerating {
                    AppBadge(text: "Generating", tone: .info, systemImage: "sparkles")
                } else {
                    AppBadge(text: "Revision \(item.contentRevision)", tone: .neutral, systemImage: "clock.arrow.circlepath")
                }
            }

            AdaptiveMetricGrid(minWidth: 150) {
                metricValue("Words", value: "\(wordCount)")
                metricValue("Characters", value: "\(item.content.count)")
                metricValue("Questions", value: "\(totalQuestionCount)")
                metricValue("Answered", value: "\(item.answeredQuestions.count)")
            }
        }
        .appCardStyle()
    }

    private func metricValue(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DocumentStartActions: View {
    let isGenerating: Bool
    let onStartQuiz: () -> Void
    let onAskDocument: () -> Void
    let onAnalytics: () -> Void
    let onSpacedRepetition: () -> Void

    var body: some View {
        #if os(macOS)
        macBody
        #else
        mobileBody
        #endif
    }

    #if os(macOS)
    private var macBody: some View {
        VStack(spacing: 12) {
            Button(action: onStartQuiz) {
                Label("Start Quiz", systemImage: "play.fill")
            }
            .buttonStyle(QuizActionButtonStyle(tone: .info))
            .disabled(isGenerating)
            .accessibilityIdentifier("open-quiz-options")

            if isGenerating {
                Label("Generating questions", systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            supportingActions
        }
    }
    #endif

    private var mobileBody: some View {
        VStack(spacing: 12) {
            Button("Start Quiz", action: onStartQuiz)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isGenerating)
                .accessibilityIdentifier("open-quiz-options")

            supportingActions
        }
    }

    private var supportingActions: some View {
        Group {
            Button {
                onAskDocument()
            } label: {
                Label("Ask Document", systemImage: "text.bubble")
            }
            .buttonStyle(QuizActionButtonStyle(tone: .info))
            .accessibilityIdentifier("open-document-qa")

            Button {
                onAnalytics()
            } label: {
                Label("View Analytics", systemImage: "chart.bar")
            }
            .buttonStyle(QuizActionButtonStyle(tone: .success))
            .accessibilityIdentifier("open-analytics")

            Button {
                onSpacedRepetition()
            } label: {
                Label("Spaced Repetition", systemImage: "brain.head.profile")
            }
            .buttonStyle(QuizActionButtonStyle(tone: .warning))
            .accessibilityIdentifier("open-spaced-repetition")
        }
    }
}

private struct DocumentStatusCard: View {
    let title: String
    let message: String
    let tone: AppStatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppBadge(text: title, tone: tone)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
    }
}

private struct QuizHeaderCard: View {
    let currentIndex: Int
    let totalQuestions: Int
    let isUnlimited: Bool
    let currentPoints: Int
    let progress: Double
    let onEndQuiz: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Question \(currentIndex + 1)")
                        .font(.title3.weight(.semibold))
                    if isUnlimited {
                        Text("\(totalQuestions) loaded so far")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("of \(totalQuestions)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                AppBadge(text: "\(currentPoints) pts", tone: .info, systemImage: "star.fill")
            }

            ProgressView(value: progress)
                .tint(.blue)

            Button("End Quiz", role: .destructive, action: onEndQuiz)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .appCardStyle()
    }
}

private struct QuizNavigationFooter: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Previous", action: onPrevious)
                .buttonStyle(.bordered)
                .disabled(!canGoBack)

            Spacer()

            Button("Next", action: onNext)
                .buttonStyle(.borderedProminent)
                .disabled(!canGoForward)
        }
        .padding(.horizontal, 4)
    }
}

#Preview("Document Start") {
    NavigationStack {
        DocumentView(item: PreviewData.sampleItem())
            .environment(AppStore())
    }
}

#Preview("Quiz State") {
    let item = PreviewData.sampleItem()
    let previewViewModel = DocumentViewModel(item: item)
    previewViewModel.currentQuizSettings = .default
    previewViewModel.hasStartedQuiz = true
    previewViewModel.currentSessionQuestions = [
        .multipleChoice(item.questions[0], originalIndex: 0)
    ]
    previewViewModel.currentQuestionIndex = 0

    return NavigationStack {
        DocumentView(viewModel: previewViewModel)
            .environment(AppStore())
    }
}
