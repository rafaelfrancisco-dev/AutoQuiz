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
                    
                    if selectedQuestionType == .multipleChoice && !viewModel.item.questions.isEmpty {
                        if viewModel.item.questions.indices.contains(viewModel.currentQuestionIndex) {
                            MultipleQuestionView(question: viewModel.item.questions[viewModel.currentQuestionIndex]) { isValid in
                                viewModel.answeredQuestion(question: viewModel.item.questions[viewModel.currentQuestionIndex], correct: isValid)
                            }
                            .padding()
                        }
                    } else if selectedQuestionType == .trueFalse && !viewModel.item.safeTrueFalseQuestions.isEmpty {
                        if viewModel.item.safeTrueFalseQuestions.indices.contains(viewModel.currentQuestionIndex) {
                            TrueFalseQuestionView(question: viewModel.item.safeTrueFalseQuestions[viewModel.currentQuestionIndex]) { isValid in
                                viewModel.answeredTrueFalseQuestion(question: viewModel.item.safeTrueFalseQuestions[viewModel.currentQuestionIndex], correct: isValid)
                            }
                            .padding()
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
        !viewModel.item.questions.isEmpty || !viewModel.item.safeTrueFalseQuestions.isEmpty
    }
    
    private var questionTypeToggle: some View {
        Picker("Question Type", selection: $selectedQuestionType) {
            if !viewModel.item.questions.isEmpty {
                Text(QuestionType.multipleChoice.rawValue).tag(QuestionType.multipleChoice)
            }
            if !viewModel.item.safeTrueFalseQuestions.isEmpty {
                Text(QuestionType.trueFalse.rawValue).tag(QuestionType.trueFalse)
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
                    viewModel.item.safeTrueFalseQuestions.count - 1
                
                if viewModel.currentQuestionIndex < maxIndex {
                    withAnimation {
                        viewModel.currentQuestionIndex += 1
                    }
                }
            }
            .disabled(viewModel.currentQuestionIndex >= (selectedQuestionType == .multipleChoice ? 
                viewModel.item.questions.count - 1 : 
                viewModel.item.safeTrueFalseQuestions.count - 1))
        }
        .padding()
    }
}

#Preview {
    DocumentView(item: Item(timestamp: .now, content: "Test"))
}
