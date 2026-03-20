import SwiftUI

struct DocumentQuestionAnsweringView: View {
    @Bindable var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Ask a Question") {
                    TextField(
                        "Ask something about this document",
                        text: $viewModel.documentQuestionInput,
                        axis: .vertical
                    )
                    .lineLimit(3...6)

                    Button(action: submitQuestion) {
                        if viewModel.isSubmittingDocumentQuestion {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Asking Document...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Ask Document", systemImage: "text.bubble")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        viewModel.isSubmittingDocumentQuestion ||
                        viewModel.documentQuestionInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    if let issueMessage = viewModel.documentQuestionAnswerIssueMessage {
                        Text(issueMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    if viewModel.isLoadingDocumentQuestionAnswers {
                        HStack {
                            ProgressView()
                            Text("Loading saved answers...")
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.documentQuestionAnswers.isEmpty {
                        ContentUnavailableView(
                            "No Saved Answers",
                            systemImage: "text.bubble",
                            description: Text("Ask a question to save a document-grounded answer for this version.")
                        )
                    } else {
                        ForEach(viewModel.documentQuestionAnswers) { questionAnswer in
                            DocumentQuestionAnswerRow(questionAnswer: questionAnswer)
                        }
                    }
                } header: {
                    HStack {
                        Text("Saved Answers")
                        Spacer()
                        Text(viewModel.selectedDocumentQuestionRevisionSelection.displayName(for: viewModel.item))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Ask Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(viewModel.documentQuestionRevisionOptions, id: \.self) { selection in
                            Button {
                                viewModel.selectedDocumentQuestionRevisionSelection = selection
                            } label: {
                                if selection == viewModel.selectedDocumentQuestionRevisionSelection {
                                    Label(selection.displayName(for: viewModel.item), systemImage: "checkmark")
                                } else {
                                    Text(selection.displayName(for: viewModel.item))
                                }
                            }
                        }
                    } label: {
                        Label("Versions", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                }
            }
        }
        .task(id: viewModel.selectedDocumentQuestionRevisionSelection) {
            await viewModel.loadDocumentQuestionAnswers()
        }
    }

    private func submitQuestion() {
        Task {
            await viewModel.submitDocumentQuestion()
        }
    }
}

private struct DocumentQuestionAnswerRow: View {
    let questionAnswer: DocumentQuestionAnswer

    private var statusLabel: String {
        switch questionAnswer.responseKind {
        case .answered:
            return "Document answer"
        case .insufficientDocumentContent:
            return "Not supported by document"
        }
    }

    private var statusColor: Color {
        switch questionAnswer.responseKind {
        case .answered:
            return .secondary
        case .insufficientDocumentContent:
            return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(questionAnswer.question)
                .font(.headline)

            Text(questionAnswer.answer)
                .foregroundStyle(.primary)

            HStack {
                Text(statusLabel)
                Spacer()
                Text("v\(questionAnswer.sourceContentRevision)")
                Text(questionAnswer.timestamp, format: .dateTime.month().day().hour().minute())
            }
            .font(.caption)
            .foregroundStyle(statusColor)
        }
        .padding(.vertical, 4)
    }
}
