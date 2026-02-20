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
        #if os(macOS)
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Text("Quiz Options")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Start Quiz") {
                    onStartQuiz(settings)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!settings.isValid)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    settingsContent
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        #else
        NavigationView {
            Form {
                settingsContent
            }
            .navigationTitle("Quiz Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Quiz") {
                        onStartQuiz(settings)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!settings.isValid)
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Start Quiz") {
                        onStartQuiz(settings)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!settings.isValid)
                }
            }
            #endif
        }
        #endif
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 20) {
            // Question Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Question Configuration")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Question Type", selection: $settings.questionType) {
                    ForEach(Question.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Quiz Length
            VStack(alignment: .leading, spacing: 12) {
                Text("Quiz Length")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("Maximum Questions")
                    Spacer()
                    if settings.isUnlimitedQuestions {
                        Text("Unlimited")
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(settings.maxQuestions)")
                            .foregroundColor(.secondary)
                    }
                }
                
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
                
                Toggle("Unlimited Questions", isOn: Binding(
                    get: { settings.isUnlimitedQuestions },
                    set: { isUnlimited in
                        if isUnlimited {
                            settings.setUnlimitedQuestions()
                        } else {
                            settings.maxQuestions = 10
                        }
                    }
                ))
                
                Toggle("Shuffle Questions", isOn: $settings.shuffleQuestions)
                
                Text("Set the maximum number of questions for this quiz session.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quiz Behavior
            VStack(alignment: .leading, spacing: 12) {
                Text("Quiz Behavior")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Toggle("Include Previously Failed Questions", isOn: $settings.includeFailedQuestions)
                Toggle("Allow Skipping Questions", isOn: $settings.allowSkipQuestions)
                
                Text("Include questions you've answered incorrectly in previous sessions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Language Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Language Settings")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Toggle("Use Original Document Language", isOn: $settings.useOriginalLanguage)
                
                Text("When enabled, questions are generated using the detected document language. If unsupported, you'll choose a supported language. When disabled, questions use your app language (with the same fallback choice if needed).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        #else
        Section {
            Picker("Question Type", selection: $settings.questionType) {
                ForEach(Question.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Question Configuration")
        }
        
        Section {
            HStack {
                Text("Maximum Questions")
                Spacer()
                if settings.isUnlimitedQuestions {
                    Text("Unlimited")
                        .foregroundColor(.secondary)
                } else {
                    Text("\(settings.maxQuestions)")
                        .foregroundColor(.secondary)
                }
            }
            
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
            
            Toggle("Unlimited Questions", isOn: Binding(
                get: { settings.isUnlimitedQuestions },
                set: { isUnlimited in
                    if isUnlimited {
                        settings.setUnlimitedQuestions()
                    } else {
                        settings.maxQuestions = 10
                    }
                }
            ))
            
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
            Text("Include questions you've answered incorrectly in previous sessions.")
        }
        
        Section {
            Toggle("Use Original Document Language", isOn: $settings.useOriginalLanguage)
        } header: {
            Text("Language Settings")
        } footer: {
            Text("When enabled, questions are generated using the detected document language. If unsupported, you'll choose a supported language. When disabled, questions use your app language (with the same fallback choice if needed).")
        }
        #endif
    }
}

#Preview {
    QuizOptionsView { settings in
        print("Starting quiz with settings: \(settings)")
    }
}
