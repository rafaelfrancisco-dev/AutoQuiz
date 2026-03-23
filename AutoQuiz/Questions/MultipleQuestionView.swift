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

        _selectedAnswer = State(initialValue: previousAnswer)
        _hasAnswered = State(initialValue: previousAnswer != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.question)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    let style = QuestionButtonStyle.forMultipleChoice(
                        option: option,
                        correctAnswer: question.answer,
                        selectedAnswer: selectedAnswer,
                        hasAnswered: hasAnswered
                    )

                    AnswerOptionButton(title: option, style: style) {
                        selectOption(option)
                    }
                    .disabled(hasAnswered)
                }
            }
        }
        .appCardStyle()
        .accessibilityIdentifier("quiz-question-card")
    }

    private func selectOption(_ option: String) {
        guard !hasAnswered else { return }
        selectedAnswer = option
        hasAnswered = true
        onQuestionAnswered(option == question.answer, option)
    }
}

#Preview {
    MultipleQuestionView(question: MultipleChoiceQuestion(question: "Yes ?", options: ["Yes", "No"], answer: "Yes")) { _, _ in }
}
