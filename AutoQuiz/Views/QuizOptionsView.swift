//
//  QuizOptionsView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI

struct QuizOptionsView: View {
    @State private var settings = QuizSettings.default
    @Environment(\.dismiss) private var dismiss

    let onStartQuiz: (QuizSettings) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Question Type") {
                    Picker("Question Type", selection: $settings.questionType) {
                        ForEach(Question.allCases.filter { $0 != .spacedRepetition }, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("quiz-question-type-picker")
                }

                Section {
                    LabeledContent("Maximum Questions", value: settings.maxQuestionsDescription)

                    if !settings.isUnlimitedQuestions {
                        Slider(
                            value: Binding(
                                get: { Double(settings.maxQuestions) },
                                set: { settings.maxQuestions = Int($0) }
                            ),
                            in: 1...50,
                            step: 1
                        )
                    }

                    Toggle("Unlimited Questions", isOn: unlimitedQuestionsBinding)
                    Toggle("Shuffle Questions", isOn: $settings.shuffleQuestions)
                } header: {
                    Text("Quiz Length")
                } footer: {
                    Text("Set the maximum number of questions for this quiz session.")
                }

                Section {
                    Toggle("Include Previously Failed Questions", isOn: $settings.includeFailedQuestions)
                    Toggle("Allow Skipping Questions", isOn: $settings.allowSkipQuestions)
                } header: {
                    Text("Quiz Behavior")
                } footer: {
                    Text("Include questions you answered incorrectly in previous sessions, and control whether unanswered questions can be skipped.")
                }

                Section {
                    Toggle("Use Original Document Language", isOn: $settings.useOriginalLanguage)
                } header: {
                    Text("Language Settings")
                } footer: {
                    Text("If the detected language is unsupported, the app will ask you to choose a supported fallback language.")
                }
            }
            .accessibilityIdentifier("quiz-options-screen")
            .navigationTitle("Quiz Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Quiz") {
                        onStartQuiz(settings)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!settings.isValid)
                    .accessibilityIdentifier("confirm-start-quiz")
                }
            }
        }
        .macModalSize(.form)
    }

    private var unlimitedQuestionsBinding: Binding<Bool> {
        Binding(
            get: { settings.isUnlimitedQuestions },
            set: { isUnlimited in
                if isUnlimited {
                    settings.setUnlimitedQuestions()
                } else {
                    settings.maxQuestions = 10
                }
            }
        )
    }
}

#Preview {
    QuizOptionsView { _ in }
}
