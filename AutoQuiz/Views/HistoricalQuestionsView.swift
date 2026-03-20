//
//  HistoricalQuestionsView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import SwiftUI

struct HistoricalQuestionsView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRevisionSelection: ContentRevisionSelection = .current

    private var sortedAnsweredQuestions: [AnsweredQuestion] {
        item.answeredQuestions
            .filter { question in
                guard let selectedSourceContentRevision else { return true }
                return question.sourceContentRevision == selectedSourceContentRevision
            }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var selectedSourceContentRevision: Int? {
        selectedRevisionSelection.resolvedRevision(for: item)
    }

    private var revisionOptions: [ContentRevisionSelection] {
        var options: [ContentRevisionSelection] = [.current]
        options.append(contentsOf: item.availableContentRevisions
            .filter { $0 != item.contentRevision }
            .map(ContentRevisionSelection.revision))
        return options
    }

    var body: some View {
        AppModalContainer(title: "Question History", maxWidth: 820, onDismiss: { dismiss() }) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Content Version", selection: $selectedRevisionSelection) {
                    ForEach(revisionOptions, id: \.self) { selection in
                        Text(selection.displayName(for: item))
                            .tag(selection)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                if sortedAnsweredQuestions.isEmpty {
                    AppEmptyState(
                        title: "No Questions Answered",
                        systemImage: "questionmark.circle",
                        description: "Start a quiz to see your answered question history here."
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedAnsweredQuestions, id: \.id) { answeredQuestion in
                            HistoricalQuestionRow(answeredQuestion: answeredQuestion)
                        }
                    }
                }
            }
            .accessibilityIdentifier("question-history-screen")
        }
        .macModalSize(.history)
    }
}

struct HistoricalQuestionRow: View {
    let answeredQuestion: AnsweredQuestion

    private var resultTone: AppStatusTone {
        answeredQuestion.isCorrect ? .success : .danger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                AppBadge(
                    text: answeredQuestion.isCorrect ? "Correct" : "Incorrect",
                    tone: resultTone,
                    systemImage: answeredQuestion.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                )

                AppBadge(text: answeredQuestion.questionType.displayName, tone: .neutral)
                AppBadge(text: "v\(answeredQuestion.sourceContentRevision)", tone: .info)

                Spacer()

                Text(answeredQuestion.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(answeredQuestion.questionText)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                answerRow(title: "Your answer", value: answeredQuestion.userAnswer, tone: resultTone)

                if !answeredQuestion.isCorrect {
                    answerRow(title: "Correct answer", value: answeredQuestion.correctAnswer, tone: .success)
                }

                answerRow(title: "Points earned", value: "\(answeredQuestion.pointsEarned)", tone: .info)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
    }

    private func answerRow(title: String, value: String, tone: AppStatusTone) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tone.tint)
        }
    }
}

#Preview("History Populated") {
    HistoricalQuestionsView(item: PreviewData.sampleItem())
}

#Preview("History Empty") {
    HistoricalQuestionsView(item: PreviewData.emptyItem())
}
