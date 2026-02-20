//
//  HistoricalQuestionsView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import SwiftUI
import SwiftData

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
    
    private var versionSelector: some View {
        Picker("Content Version", selection: $selectedRevisionSelection) {
            ForEach(revisionOptions, id: \.self) { selection in
                Text(selection.displayName(for: item))
                    .tag(selection)
            }
        }
        .pickerStyle(.menu)
    }
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                
                Text("Question History")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            Group {
                VStack(alignment: .leading, spacing: 12) {
                    versionSelector
                    
                    if sortedAnsweredQuestions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No Questions Answered")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Start a quiz to see your answered questions history here.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            ForEach(sortedAnsweredQuestions, id: \.timestamp) { answeredQuestion in
                                HistoricalQuestionRow(answeredQuestion: answeredQuestion)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 400)
        }
        #else
        NavigationStack {
            VStack(spacing: 12) {
                versionSelector
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Group {
                    if sortedAnsweredQuestions.isEmpty {
                        ContentUnavailableView(
                            "No Questions Answered",
                            systemImage: "questionmark.circle",
                            description: Text("Start a quiz to see your answered questions history here.")
                        )
                    } else {
                        List {
                            ForEach(sortedAnsweredQuestions, id: \.timestamp) { answeredQuestion in
                                HistoricalQuestionRow(answeredQuestion: answeredQuestion)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Question History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #endif
    }
}

struct HistoricalQuestionRow: View {
    let answeredQuestion: AnsweredQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: answeredQuestion.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(answeredQuestion.isCorrect ? .green : .red)
                
                Text(answeredQuestion.questionType.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Text("v\(answeredQuestion.sourceContentRevision)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                Text(answeredQuestion.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(answeredQuestion.questionText)
                .font(.body)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Your answer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(answeredQuestion.userAnswer)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(answeredQuestion.isCorrect ? .green : .red)
                }
                
                if !answeredQuestion.isCorrect {
                    HStack {
                        Text("Correct answer:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(answeredQuestion.correctAnswer)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Text("Points earned:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(answeredQuestion.pointsEarned)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleItem = Item(timestamp: .now, content: "Sample content")
    
    sampleItem.answeredQuestions = [
        AnsweredQuestion(
            questionText: "What is the capital of France?",
            userAnswer: "Paris",
            correctAnswer: "Paris",
            isCorrect: true,
            pointsEarned: 10,
            questionType: .multipleChoice,
            sourceContentRevision: 2
        ),
        AnsweredQuestion(
            questionText: "Is the Earth flat?",
            userAnswer: "True",
            correctAnswer: "False",
            isCorrect: false,
            pointsEarned: 0,
            questionType: .trueFalse,
            sourceContentRevision: 1
        )
    ]
    
    return HistoricalQuestionsView(item: sampleItem)
}
