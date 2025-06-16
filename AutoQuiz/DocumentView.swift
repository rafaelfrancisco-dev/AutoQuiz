//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import SwiftData

struct DocumentView: View {
    @State private var viewModel: DocumentViewModel
    @Environment(\.modelContext) private var modelContext
    
    init(item: Item) {
        self.viewModel = DocumentViewModel(item: item)
    }
    
    var body: some View {
        VStack {
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
                    print(error.localizedDescription)
                }
                
                withAnimation {
                    viewModel.isGenerating = false
                }
            }
            
            viewModel.startBackgroundGeneration()
        }
        .navigationTitle(viewModel.item.title ?? viewModel.item.timestamp.description)
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
            let results = viewModel.quizResults
            Text("Questions answered: \(results.totalQuestions)\nCorrect answers: \(results.correctAnswers)\nPoints earned: \(results.totalPoints)")
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
                    withAnimation {
                        viewModel.startQuiz()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasQuestionsForType(viewModel.selectedQuestionType))
                .controlSize(.large)
            }
            .padding()
            
            if !hasQuestionsForType(viewModel.selectedQuestionType) {
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
                
                if viewModel.selectedQuestionType == .multipleChoice {
                    if !viewModel.item.questions.isEmpty {
                        if viewModel.item.questions.indices.contains(viewModel.currentQuestionIndex) {
                            let question = viewModel.item.questions[viewModel.currentQuestionIndex]
                            let previousAnswer = viewModel.getPreviousAnswer(for: question)
                            MultipleQuestionView(question: question, previousAnswer: previousAnswer) { isValid, userAnswer in
                                viewModel.answeredQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                            }
                            .padding()
                            .id("multiple-\(viewModel.currentQuestionIndex)")
                        }
                    } else {
                        generateQuestionButton
                    }
                } else if viewModel.selectedQuestionType == .trueFalse {
                    if !(viewModel.item.trueFalseQuestions ?? []).isEmpty {
                        if (viewModel.item.trueFalseQuestions ?? []).indices.contains(viewModel.currentQuestionIndex) {
                            let question = viewModel.item.trueFalseQuestions![viewModel.currentQuestionIndex]
                            let previousAnswer = viewModel.getPreviousAnswer(for: question)
                            TrueFalseQuestionView(question: question, previousAnswer: previousAnswer) { isValid, userAnswer in
                                viewModel.answeredTrueFalseQuestion(question: question, correct: isValid, userAnswer: userAnswer)
                            }
                            .padding()
                            .id("truefalse-\(viewModel.currentQuestionIndex)")
                        }
                    } else {
                        generateQuestionButton
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
    
    private var generateQuestionButton: some View {
        VStack {
            if viewModel.isGenerating {
                ProgressView()
            }
            
            Button("Generate \(viewModel.selectedQuestionType.rawValue.capitalized) Question") {
                Task {
                    withAnimation {
                        viewModel.isGenerating = true
                    }
                    
                    do {
                        if viewModel.selectedQuestionType == .multipleChoice {
                            let results = try await viewModel.generator.generateMultipleChoiceQuestions()
                            withAnimation {
                                viewModel.item.questions.append(contentsOf: results)
                                viewModel.currentQuestionIndex = 0
                            }
                        } else {
                            let results = try await viewModel.generator.generateTrueFalseQuestions()
                            withAnimation {
                                if viewModel.item.trueFalseQuestions == nil {
                                    viewModel.item.trueFalseQuestions = []
                                }
                                viewModel.item.trueFalseQuestions?.append(contentsOf: results)
                                viewModel.currentQuestionIndex = 0
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    withAnimation {
                        viewModel.isGenerating = false
                    }
                }
            }
            .disabled(viewModel.isGenerating)
        }
    }
}

#Preview {
    DocumentView(item: Item(timestamp: .now, content: "Test"))
}
