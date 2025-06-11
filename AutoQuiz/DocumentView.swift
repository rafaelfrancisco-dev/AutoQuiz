//
//  DocumentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import FoundationModels

struct DocumentView: View {
    let text: String
    let timestamp: Date
    
    @State private var isGenerating = false
    
    @State private var question: Question?
    @State private var title: String?
    
    private func generateQuestion(_ session: LanguageModelSession) async throws -> Question {
        let textToPrompt = text.prefix(3800)
        
        let response = try await session.respond(
            to: "Generate a multiple choice question with 4 choices for this content: \(textToPrompt)",
            generating: Question.self
        )
        
        return response.content
    }
    
    private func generateTitle(_ session: LanguageModelSession) async throws -> String {
        let textToPrompt = text.prefix(3800)
        
        let response = try await session.respond(
            to: "Create a title for this content with 6 words max: \(textToPrompt)"
        )
        
        return response.content
    }
    
    var body: some View {
        GenerativeView { session in
            if let question {
                VStack {
                    Text(question.question)
                    
                    ForEach(question.options, id: \.self) { q in
                        Button(q) {
                            
                        }
                    }
                    
                    Text("correct answer is: \(question.anwswer)")
                }
            } else {
                Button("generate") {
                    Task {
                        withAnimation {
                            isGenerating = true
                        }
                        
                        do {
                            let result = try await generateQuestion(session)
                            
                            withAnimation {
                                question = result
                            }
                            
                            let title = try await generateTitle(session)
                            
                            print(title)
                        } catch {
                            print(error.localizedDescription)
                        }
                        
                        withAnimation {
                            isGenerating = false
                        }
                    }
                }
                .disabled(isGenerating)
                .task {
                    if title == nil {
                        withAnimation {
                            isGenerating = true
                        }
                        
                        do {
                            let title = try await generateTitle(session)
                            
                            withAnimation {
                                self.title = title
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
        .navigationTitle(title ?? timestamp.description)
    }
}

#Preview {
    DocumentView(text: "test", timestamp: .now)
}
