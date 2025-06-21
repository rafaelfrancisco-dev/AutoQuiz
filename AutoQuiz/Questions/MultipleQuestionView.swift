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
    let previousAnswer: String?
    
    @State private var selectedAnswer: String?
    @State private var hasAnswered = false
    
    init(question: MultipleChoiceQuestion, previousAnswer: String? = nil, onQuestionAnswered: @escaping (Bool, String) -> Void) {
        self.question = question
        self.previousAnswer = previousAnswer
        self.onQuestionAnswered = onQuestionAnswered
        
        // Initialize state based on previous answer
        _selectedAnswer = State(initialValue: previousAnswer)
        _hasAnswered = State(initialValue: previousAnswer != nil)
    }
    
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
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .tint(buttonTintColor(for: option))
                    .disabled(hasAnswered)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func buttonTintColor(for option: String) -> Color {
        guard hasAnswered else { return .blue }
        
        if option == question.anwswer {
            return .green
        } else if option == selectedAnswer {
            return .red
        } else {
            return .gray
        }
    }
}

#Preview {
    MultipleQuestionView(question: MultipleChoiceQuestion(question: "Yes ?", options: ["Yes", "No"], anwswer: "Yes")) { _, _ in }
}
