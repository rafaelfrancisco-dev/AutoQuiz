//
//  TrueFalseQuestionView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 15/06/2025.
//

import SwiftUI

struct TrueFalseQuestionView: View {
    let question: TrueFalseQuestion
    let onQuestionAnswered: (Bool, Bool) -> Void
    let previousAnswer: Bool?
    
    @State private var selectedAnswer: Bool?
    @State private var hasAnswered = false
    
    init(question: TrueFalseQuestion, previousAnswer: Bool? = nil, onQuestionAnswered: @escaping (Bool, Bool) -> Void) {
        self.question = question
        self.previousAnswer = previousAnswer
        self.onQuestionAnswered = onQuestionAnswered
        
        // Initialize state based on previous answer
        _selectedAnswer = State(initialValue: previousAnswer)
        _hasAnswered = State(initialValue: previousAnswer != nil)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text(question.question)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack(spacing: 40) {
                Button("True") {
                    if !hasAnswered {
                        selectedAnswer = true
                        hasAnswered = true
                        let isCorrect = question.isTrue
                        onQuestionAnswered(isCorrect, true)
                    }
                }
                .frame(width: 120, height: 50)
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(buttonTintColor(for: true))
                .disabled(hasAnswered)
                
                Button("False") {
                    if !hasAnswered {
                        selectedAnswer = false
                        hasAnswered = true
                        let isCorrect = !question.isTrue
                        onQuestionAnswered(isCorrect, false)
                    }
                }
                .frame(width: 120, height: 50)
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(buttonTintColor(for: false))
                .disabled(hasAnswered)
            }
        }
    }
    
    private func buttonTintColor(for answer: Bool) -> Color {
        guard hasAnswered else { return .blue }
        
        if answer == question.isTrue {
            return .green
        } else if answer == selectedAnswer {
            return .red
        } else {
            return .gray
        }
    }
}

#Preview {
    TrueFalseQuestionView(question: TrueFalseQuestion(question: "Swift is a programming language?", isTrue: true)) { _, _ in }
}