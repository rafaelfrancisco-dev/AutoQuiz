//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import SwiftData
import OSLog

struct GenerationLoadingIndicator: View {
    let message: String
    let scale: CGFloat
    
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(scale)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct DocumentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: DocumentViewModel
    @State private var showingHistoricalQuestions = false
    @State private var showingQuizOptions = false
    @State private var showingAddContent = false
    @State private var showingAnalytics = false
    @State private var showingSpacedRepetition = false
    
    init(item: Item) {
        self.viewModel = DocumentViewModel(item: item)
    }
    
    var body: some View {
        List {
            if viewModel.hasStartedQuiz {
                quizView
            } else {
                startView
            }
        }
        .task {
            if viewModel.item.title == nil {
                withAnimation {
                    viewModel.isGenerating = true
                }
                
                do {
                    let title = try await viewModel.generator.generateTitle()
                    
                    withAnimation {
                        viewModel.item.title = title
                        viewModel.generationIssue = nil
                    }
                } catch let error as GeneratorError {
                    viewModel.generationIssue = error
                    Logger.error.error("Failed to generate title: \(error.userFacingMessage)")
                } catch {
                    Logger.error.error("Failed to generate title: \(error.localizedDescription)")
                }
                
                withAnimation {
                    viewModel.isGenerating = false
                }
            }
            
            viewModel.startBackgroundGeneration()
        }
        .navigationTitle(viewModel.item.title ?? viewModel.item.timestamp.description)
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add Content") {
                        showingAddContent = true
                    }
                    
                    Divider()
                    
                    Button("Question History") {
                        showingHistoricalQuestions = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Add Content") {
                        showingAddContent = true
                    }
                    
                    Divider()
                    
                    Button("Question History") {
                        showingHistoricalQuestions = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        #endif
        .sheet(isPresented: $showingHistoricalQuestions) {
            HistoricalQuestionsView(item: viewModel.item)
        }
        .sheet(isPresented: $showingQuizOptions) {
            QuizOptionsView { settings in
                withAnimation {
                    viewModel.startQuiz(with: settings)
                }
            }
        }
        .sheet(isPresented: $showingAddContent) {
            AddContentView(item: viewModel.item)
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView(document: viewModel.item)
        }
        .sheet(isPresented: $showingSpacedRepetition) {
            SpacedRepetitionView(document: viewModel.item)
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
        .onDisappear {
            viewModel.stopBackgroundGeneration()
        }
        .alert("Quiz Results", isPresented: $viewModel.showingResults) {
            Button("Start New Quiz") {
                viewModel.resetQuiz()
            }
            
            Button("Cancel") {
                viewModel.showingResults = false
            }
        } message: {
            Text("Questions answered: \(viewModel.quizResults.totalQuestions)\nCorrect answers: \(viewModel.quizResults.correctAnswers)\nPoints earned: \(viewModel.quizResults.totalPoints)")
        }
    }
    
    private var hasQuestions: Bool {
        !viewModel.item.questions.isEmpty || !(viewModel.item.trueFalseQuestions ?? []).isEmpty
    }
    
    @ViewBuilder
    private var startView: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 20) {
                contentDetailsView
                
                VStack(spacing: 12) {
                    Button {
                        withAnimation {
                            showingQuizOptions = true
                        }
                    } label: {
                        Text("Start Quiz")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isGenerating)
                    .controlSize(.large)
                    
                    Button {
                        showingAnalytics = true
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar")
                            Text("View Analytics")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button {
                        showingSpacedRepetition = true
                    } label: {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Spaced Repetition")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            
            if let generationIssueMessage = viewModel.generationIssueMessage {
                Text(generationIssueMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            } else if !viewModel.isGenerating && !hasQuestionsForType(viewModel.selectedQuestionType) {
                Text("Generating questions in the background...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var quizView: some View {
        ScrollView {
            VStack {
                questionProgressIndicator
                
                HStack {
                    pointsDisplay
                    
                    Spacer()
                    
                    Button("End Quiz") {
                        viewModel.endQuiz()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Spacer()
                    .frame(height: 20)
                
                if let currentSessionQuestion = viewModel.getCurrentSessionQuestion() {
                    switch currentSessionQuestion {
                    case .multipleChoice(let question, _):
                        let previousAnswer = viewModel.getPreviousAnswer(for: question)
                        
                        MultipleQuestionView(question: question, previousAnswer: previousAnswer) { isValid, userAnswer in
                            viewModel.answeredQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                        }
                        .padding()
                        .id("multiple-\(viewModel.currentQuestionIndex)")
                        
                    case .trueFalse(let question, _):
                        let previousAnswer = viewModel.getPreviousAnswer(for: question)
                        
                        TrueFalseQuestionView(question: question, previousAnswer: previousAnswer) { isValid, userAnswer in
                            viewModel.answeredTrueFalseQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                        }
                        .padding()
                        .id("truefalse-\(viewModel.currentQuestionIndex)")
                        
                    case .spacedRepetition(_):
                        // Spaced repetition should not appear in regular quiz sessions
                        // It has its own dedicated view and workflow
                        Text("Spaced repetition cards should not appear in regular quizzes")
                            .foregroundColor(.red)
                            .padding()
                    }
                } else {
                    // Fallback to original logic for non-session quiz
                    if viewModel.selectedQuestionType == .multipleChoice {
                        if !viewModel.item.questions.isEmpty && viewModel.item.questions.indices.contains(viewModel.currentQuestionIndex) {
                            let question = viewModel.item.questions[viewModel.currentQuestionIndex]
                            let previousAnswer = viewModel.getPreviousAnswer(for: question)
                            
                            MultipleQuestionView(question: question, previousAnswer: previousAnswer) { isValid, userAnswer in
                                viewModel.answeredQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                            }
                            .padding()
                            .id("multiple-\(viewModel.currentQuestionIndex)")
                        }
                    } else if viewModel.selectedQuestionType == .trueFalse {
                        if !(viewModel.item.trueFalseQuestions ?? []).isEmpty && (viewModel.item.trueFalseQuestions ?? []).indices.contains(viewModel.currentQuestionIndex) {
                            let question = viewModel.item.trueFalseQuestions![viewModel.currentQuestionIndex]
                            let previousAnswer = viewModel.getPreviousAnswer(for: question)
                            
                            TrueFalseQuestionView(question: question, previousAnswer: previousAnswer) { isValid, userAnswer in
                                viewModel.answeredTrueFalseQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                            }
                            .padding()
                            .id("truefalse-\(viewModel.currentQuestionIndex)")
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 20)
                
                if viewModel.shouldShowWaitingIndicator {
                    GenerationLoadingIndicator(
                        message: "Generating next question...",
                        scale: 0.8
                    )
                    .padding()
                }
                
                navigationControls
            }
        }
    }
    
    private func hasQuestionsForType(_ type: Question) -> Bool {
        switch type {
        case .multipleChoice:
            return !viewModel.item.questions.isEmpty
        case .trueFalse:
            return !(viewModel.item.trueFalseQuestions ?? []).isEmpty
        case .spacedRepetition:
            // Spaced repetition always has questions available since it uses its own system
            return true
        }
    }
    
    private var pointsDisplay: some View {
        Text("Points: \(viewModel.currentPoints)")
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    
    private var contentDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Details")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Word Count:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(wordCount)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "textformat.abc")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Character Count:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.item.content.count)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Available Questions:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(totalQuestionCount)")
                        .fontWeight(.medium)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
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
    
    private var questionProgressIndicator: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Question \(viewModel.currentQuestionIndex + 1)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
                
                if !viewModel.currentQuizSettings.isUnlimitedQuestions {
                    Text("of \(viewModel.currentQuizSettings.maxQuestions)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if viewModel.hasStartedQuiz {
                    Text("of \(viewModel.currentSessionQuestions.count)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.currentQuestionIndex)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.currentSessionQuestions.count)
            
            if !viewModel.currentQuizSettings.isUnlimitedQuestions {
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(viewModel.currentQuizSettings.maxQuestions))
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 6)
                    .scaleEffect(x: 1, y: 1.5)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.currentQuestionIndex)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var navigationControls: some View {
        HStack {
            Button("Previous") {
                if viewModel.currentQuestionIndex > 0 {
                    withAnimation {
                        viewModel.currentQuestionIndex -= 1
                    }
                }
            }
            .disabled(viewModel.currentQuestionIndex == 0)
            
            Spacer()
            
            if viewModel.canNavigateToNext {
                Button("Next") {
                    withAnimation {
                        viewModel.currentQuestionIndex += 1
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
    }
    
}

#Preview {
    DocumentView(item: Item(timestamp: .now, content: "Test"))
}
