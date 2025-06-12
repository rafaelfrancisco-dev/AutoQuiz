//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import FoundationModels

struct DocumentView: View {
    let item: Item
    
    @State private var isGenerating = false
    
    private func generateQuestion(_ session: LanguageModelSession) async throws -> Question {
        let textToPrompt = item.content.prefix(3800)
        
        let response = try await session.respond(
            to: "Generate a multiple choice question with 4 choices for this content: \(textToPrompt)",
            generating: Question.self
        )
        
        return response.content
    }
    
    private func generateTitle(_ session: LanguageModelSession) async throws -> String {
        let textToPrompt = item.content.prefix(3800)
        
        let response = try await session.respond(
            to: "Create a title for this content with 6 words max: \(textToPrompt)"
        )
        
        return response.content
    }
    
    var body: some View {
        GenerativeView { session in
            if let question = item.questions.first {
                QuestionView(question: question) { isValid in
                    
                }
            } else {
                VStack {
                    if isGenerating {
                        ProgressView()
                    }
                    
                    if item.questions.isEmpty {
                        Button("generate") {
                            Task {
                                withAnimation {
                                    isGenerating = true
                                }
                                
                                do {
                                    let result = try await generateQuestion(session)
                                    
                                    withAnimation {
                                        item.questions.append(result)
                                    }
                                } catch {
                                    print(error.localizedDescription)
                                }
                                
                                withAnimation {
                                    isGenerating = false
                                }
                            }
                        }
                        .disabled(isGenerating)
                    }
                }
                .task {
                    if item.title == nil {
                        withAnimation {
                            isGenerating = true
                        }
                        
                        do {
                            let title = try await generateTitle(session)
                            
                            withAnimation {
                                item.title = title
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                        
                        withAnimation {
                            isGenerating = false
                        }
                    }
                }
            }
        }
        .navigationTitle(item.title ?? item.timestamp.description)
    }
}

#Preview {
    DocumentView(item: Item(timestamp: .now, content: "Test"))
}
