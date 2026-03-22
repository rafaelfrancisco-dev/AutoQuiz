//
//  QuizOptionsView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct QuizOptionsView: View {
    @State private var settings = QuizSettings.default
    @Environment(\.dismiss) private var dismiss

    let onStartQuiz: (QuizSettings) -> Void

    var body: some View {
        #if os(macOS)
        macBody
        #else
        mobileBody
        #endif
    }

    #if os(macOS)
    private var macBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppMacModalHeader(
                    title: "Quiz Options",
                    subtitle: "Choose the question style and quiz behavior for this document."
                ) {
                    Button("Close") {
                        dismiss()
                    }
                }

                AppMacFormSection(title: "Question Type") {
                    Picker("Question Type", selection: $settings.questionType) {
                        ForEach(Question.allCases.filter { $0 != .spacedRepetition }, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .accessibilityIdentifier("quiz-question-type-picker")
                }

                AppMacFormSection(
                    title: "Quiz Length",
                    footer: "Set the maximum number of questions for this quiz session."
                ) {
                    VStack(alignment: .leading, spacing: 14) {
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
                    }
                    .controlSize(.regular)
                }

                AppMacFormSection(
                    title: "Quiz Behavior",
                    footer: "Include previously missed questions and control whether unanswered questions can be skipped."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Include Previously Failed Questions", isOn: $settings.includeFailedQuestions)
                        Toggle("Allow Skipping Questions", isOn: $settings.allowSkipQuestions)
                    }
                }

                AppMacFormSection(
                    title: "Language Settings",
                    footer: "If the detected language is unsupported, the app will ask you to choose a supported fallback language."
                ) {
                    Toggle("Use Original Document Language", isOn: $settings.useOriginalLanguage)
                }

                HStack {
                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }

                    Button("Start Quiz") {
                        startQuiz()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!settings.isValid)
                    .accessibilityIdentifier("confirm-start-quiz")
                }
            }
            .padding(24)
            .frame(maxWidth: 620, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityIdentifier("quiz-options-screen")
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .macModalSize(.utilityForm)
    }
    #endif

    private var mobileBody: some View {
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
                        startQuiz()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!settings.isValid)
                    .accessibilityIdentifier("confirm-start-quiz")
                }
            }
        }
        .macModalSize(.utilityForm)
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

    private func startQuiz() {
        onStartQuiz(settings)
        dismiss()
    }
}

#Preview {
    QuizOptionsView { _ in }
}
