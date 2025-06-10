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
    
    @State private var isGenerating = false
    @State private var question: Question?
    
    private func generateQuestion(_ session: LanguageModelSession) async throws -> Question {
        let response = try await session.respond(
            to: "Generate a multiple choice question with 4 choices for this content: \(text)",
            generating: Question.self
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
    }
}

#Preview {
    DocumentView(text: "test")
}
