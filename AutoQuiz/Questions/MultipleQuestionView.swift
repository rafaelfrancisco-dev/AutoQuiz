//
//  QuestionView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 11/06/2025.
//

import SwiftUI

struct MultipleQuestionView: View {
    let question: MultipleChoiceQuestion
    let onQuestionAnswered: (Bool, String) -> Void
    
    @State private var selectedAnswer: String?
    @State private var hasAnswered = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.question)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    Button(option) {
                        if !hasAnswered {
                            selectedAnswer = option
                            hasAnswered = true
                            let isCorrect = option == question.anwswer
                            onQuestionAnswered(isCorrect, option)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonBackgroundColor(for: option))
                    .foregroundColor(buttonTextColor(for: option))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hasAnswered ? .clear : .gray, lineWidth: 1)
                    )
                    .disabled(hasAnswered)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func buttonTextColor(for option: String) -> Color {
        guard hasAnswered else { return .primary }
        
        if option == question.anwswer {
            return .white
        } else if option == selectedAnswer {
            return .white
        } else {
            return .secondary
        }
    }
    
    private func buttonBackgroundColor(for option: String) -> Color {
        guard hasAnswered else { return .gray.opacity(0.1) }
        
        if option == question.anwswer {
            return .green
        } else if option == selectedAnswer {
            return .red
        } else {
            return .gray.opacity(0.3)
        }
    }
}

#Preview {
    MultipleQuestionView(question: MultipleChoiceQuestion(question: "Yes ?", options: ["Yes", "No"], anwswer: "Yes")) { _, _ in }
}
