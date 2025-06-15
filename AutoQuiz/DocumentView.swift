//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import FoundationModels

struct DocumentView: View {
    @State private var viewModel: DocumentViewModel
    @State private var selectedQuestionType: QuestionType = .multipleChoice
    
    init(item: Item) {
        self.viewModel = DocumentViewModel(item: item)
    }
    
    var body: some View {
        GenerativeView { session in
            if hasQuestions {
                VStack {
                    questionTypeToggle
                    
                    Spacer()
                    
                    if selectedQuestionType == .multipleChoice {
                        if !viewModel.item.questions.isEmpty {
                            if viewModel.item.questions.indices.contains(viewModel.currentQuestionIndex) {
                                MultipleQuestionView(question: viewModel.item.questions[viewModel.currentQuestionIndex]) { isValid in
                                    viewModel.answeredQuestion(question: viewModel.item.questions[viewModel.currentQuestionIndex], correct: isValid)
                                }
                                .padding()
                            }
                        } else {
                            generateQuestionButton(session: session)
                        }
                    } else if selectedQuestionType == .trueFalse {
                        if !(viewModel.item.trueFalseQuestions ?? []).isEmpty {
                            if (viewModel.item.trueFalseQuestions ?? []).indices.contains(viewModel.currentQuestionIndex) {
                                TrueFalseQuestionView(question: viewModel.item.trueFalseQuestions![viewModel.currentQuestionIndex]) { isValid in
                                    viewModel.answeredTrueFalseQuestion(question: viewModel.item.trueFalseQuestions![viewModel.currentQuestionIndex], correct: isValid)
                                }
                                .padding()
                            }
                        } else {
                            generateQuestionButton(session: session)
                        }
                    }
                    
                    Spacer()
                    
                    navigationControls
                }
            } else {
                VStack {
                    if viewModel.isGenerating {
                        ProgressView()
                    }
                    
                    if !hasQuestions {
                        VStack {
                            Picker("Question Type", selection: $selectedQuestionType) {
                                ForEach(QuestionType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            
                            Button("Generate \(selectedQuestionType.rawValue) Question") {
                                Task {
                                    withAnimation {
                                        viewModel.isGenerating = true
                                    }
                                    
                                    do {
                                        if selectedQuestionType == .multipleChoice {
                                            let result = try await viewModel.generator.generateMultipleChoiceQuestion(session)
                                            withAnimation {
                                                viewModel.item.questions.append(result)
                                            }
                                        } else {
                                            let result = try await viewModel.generator.generateTrueFalseQuestion(session)
                                            withAnimation {
                                                if viewModel.item.trueFalseQuestions == nil {
                                                    viewModel.item.trueFalseQuestions = []
                                                }
                                                viewModel.item.trueFalseQuestions?.append(result)
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
                .task {
                    if viewModel.item.title == nil {
                        withAnimation {
                            viewModel.isGenerating = true
                        }
                        
                        do {
                            let title = try await viewModel.generator.generateTitle(session)
                            
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
                }
            }
        }
        .navigationTitle(viewModel.item.title ?? viewModel.item.timestamp.description)
    }
    
    private var hasQuestions: Bool {
        !viewModel.item.questions.isEmpty || !(viewModel.item.trueFalseQuestions ?? []).isEmpty
    }
    
    private var questionTypeToggle: some View {
        Picker("Question Type", selection: $selectedQuestionType) {
            ForEach(QuestionType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding()
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
            
            Button("Next") {
                let maxIndex = selectedQuestionType == .multipleChoice ?
                viewModel.item.questions.count - 1 :
                (viewModel.item.trueFalseQuestions?.count ?? 0) - 1
                
                if viewModel.currentQuestionIndex < maxIndex {
                    withAnimation {
                        viewModel.currentQuestionIndex += 1
                    }
                }
            }
            .disabled(viewModel.currentQuestionIndex >= (selectedQuestionType == .multipleChoice ?
                                                         viewModel.item.questions.count - 1 :
                                                            (viewModel.item.trueFalseQuestions?.count ?? 0) - 1))
        }
        .padding()
    }
    
    private func generateQuestionButton(session: LanguageModelSession) -> some View {
        VStack {
            if viewModel.isGenerating {
                ProgressView()
            }
            
            Button("Generate \(selectedQuestionType.rawValue) Question") {
                Task {
                    withAnimation {
                        viewModel.isGenerating = true
                    }
                    
                    do {
                        if selectedQuestionType == .multipleChoice {
                            let result = try await viewModel.generator.generateMultipleChoiceQuestion(session)
                            withAnimation {
                                viewModel.item.questions.append(result)
                                viewModel.currentQuestionIndex = 0
                            }
                        } else {
                            let result = try await viewModel.generator.generateTrueFalseQuestion(session)
                            withAnimation {
                                if viewModel.item.trueFalseQuestions == nil {
                                    viewModel.item.trueFalseQuestions = []
                                }
                                viewModel.item.trueFalseQuestions?.append(result)
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
