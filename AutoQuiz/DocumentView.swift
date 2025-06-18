//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import SwiftData
import OSLog

struct DocumentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: DocumentViewModel
    @State private var showingHistoricalQuestions = false
    @State private var showingQuizOptions = false
    
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
                    }
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
            if viewModel.isGenerating {
                ProgressView()
                    .padding()
            }
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose Question Type")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Picker("Question Type", selection: $viewModel.selectedQuestionType) {
                    ForEach(Question.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                Button("Start Quiz") {
                    showingQuizOptions = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            
            if !viewModel.isGenerating && !hasQuestionsForType(viewModel.selectedQuestionType) {
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
                HStack {
                    pointsDisplay
                    
                    Spacer()
                    
                    Button("End Quiz") {
                        viewModel.endQuiz()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                
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
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Generating next question...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                navigationControls
                    .padding(.bottom, 20)
            }
        }
    }
    
    private func hasQuestionsForType(_ type: Question) -> Bool {
        switch type {
        case .multipleChoice:
            return !viewModel.item.questions.isEmpty
        case .trueFalse:
            return !(viewModel.item.trueFalseQuestions ?? []).isEmpty
        }
    }
    
    private var pointsDisplay: some View {
        HStack {
            Text("Points: \(viewModel.currentPoints)")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.isBackgroundGenerating {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Generating questions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var questionTypeToggle: some View {
        Picker("Question Type", selection: $viewModel.selectedQuestionType) {
            ForEach(Question.allCases, id: \.self) { type in
                Text(type.rawValue.capitalized).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .onChange(of: viewModel.selectedQuestionType) { _, newType in
            withAnimation {
                viewModel.switchQuestionType(to: newType)
            }
        }
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
            }
        }
        .padding()
    }
    
}

#Preview {
    DocumentView(item: Item(timestamp: .now, content: "Test"))
}
