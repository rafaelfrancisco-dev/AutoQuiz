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

        _selectedAnswer = State(initialValue: previousAnswer)
        _hasAnswered = State(initialValue: previousAnswer != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(question.question)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                AnswerOptionButton(
                    title: "True",
                    subtitle: "Mark the statement as correct",
                    style: QuestionButtonStyle.forTrueFalse(
                        answer: true,
                        correctAnswer: question.isTrue,
                        selectedAnswer: selectedAnswer,
                        hasAnswered: hasAnswered
                    )
                ) {
                    selectAnswer(true)
                }
                .disabled(hasAnswered)

                AnswerOptionButton(
                    title: "False",
                    subtitle: "Mark the statement as incorrect",
                    style: QuestionButtonStyle.forTrueFalse(
                        answer: false,
                        correctAnswer: question.isTrue,
                        selectedAnswer: selectedAnswer,
                        hasAnswered: hasAnswered
                    )
                ) {
                    selectAnswer(false)
                }
                .disabled(hasAnswered)
            }
        }
        .appCardStyle()
        .accessibilityIdentifier("quiz-question-card")
    }

    private func selectAnswer(_ answer: Bool) {
        guard !hasAnswered else { return }
        selectedAnswer = answer
        hasAnswered = true
        onQuestionAnswered(answer == question.isTrue, answer)
    }
}

#Preview {
    TrueFalseQuestionView(question: TrueFalseQuestion(question: "Swift is a programming language?", isTrue: true)) { _, _ in }
}
