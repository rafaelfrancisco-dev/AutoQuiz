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
                .background(buttonBackgroundColor(for: true))
                .foregroundColor(buttonTextColor(for: true))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hasAnswered ? .clear : .gray, lineWidth: 1)
                )
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
                .background(buttonBackgroundColor(for: false))
                .foregroundColor(buttonTextColor(for: false))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hasAnswered ? .clear : .gray, lineWidth: 1)
                )
                .disabled(hasAnswered)
            }
        }
    }
    
    private func buttonTextColor(for answer: Bool) -> Color {
        guard hasAnswered else { return .primary }
        
        if answer == question.isTrue {
            return .white
        } else if answer == selectedAnswer {
            return .white
        } else {
            return .secondary
        }
    }
    
    private func buttonBackgroundColor(for answer: Bool) -> Color {
        guard hasAnswered else { return .gray.opacity(0.1) }
        
        if answer == question.isTrue {
            return .green
        } else if answer == selectedAnswer {
            return .red
        } else {
            return .gray.opacity(0.3)
        }
    }
}

#Preview {
    TrueFalseQuestionView(question: TrueFalseQuestion(question: "Swift is a programming language?", isTrue: true)) { _, _ in }
}