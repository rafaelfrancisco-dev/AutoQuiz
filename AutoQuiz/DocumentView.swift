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
    
    init(item: Item) {
        self.viewModel = DocumentViewModel(item: item)
    }
    
    var body: some View {
        GenerativeView { session in
            if !viewModel.item.questions.isEmpty {
                VStack {
                    if viewModel.item.questions.indices.contains(viewModel.currentQuestionIndex) {
                        QuestionView(question: viewModel.item.questions[viewModel.currentQuestionIndex]) { isValid in
                            viewModel.answeredQuestion(question: viewModel.item.questions[viewModel.currentQuestionIndex], correct: isValid)
                        }
                        .padding()
                        
                        Spacer()
                        
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
                                if viewModel.currentQuestionIndex < viewModel.item.questions.count - 1 {
                                    withAnimation {
                                        viewModel.currentQuestionIndex += 1
                                    }
                                }
                            }
                            .disabled(viewModel.currentQuestionIndex >= viewModel.item.questions.count - 1)
                        }
                        .padding()
                    }
                }
            } else {
                VStack {
                    if viewModel.isGenerating {
                        ProgressView()
                    }
                    
                    if viewModel.item.questions.isEmpty {
                        Button("generate") {
                            Task {
                                withAnimation {
                                    viewModel.isGenerating = true
                                }
                                
                                do {
                                    let result = try await viewModel.generator.generateQuestion(session)
                                    
                                    withAnimation {
                                        viewModel.item.questions.append(result)
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
}

#Preview {
    DocumentView(item: Item(timestamp: .now, content: "Test"))
}
