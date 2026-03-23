import SwiftUI
#if os(macOS)
import AppKit
#endif

struct DocumentQuestionAnsweringView: View {
    @Bindable var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

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
                    title: "Ask Document",
                    subtitle: "Save document-grounded answers for the selected content version."
                ) {
                    HStack(spacing: 12) {
                        versionMenu
                        Button("Close") {
                            dismiss()
                        }
                    }
                }

                content
                    .accessibilityIdentifier("document-qa-screen")
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: viewModel.selectedDocumentQuestionRevisionSelection) {
            await viewModel.loadDocumentQuestionAnswers()
        }
    }
    #endif

    private var mobileBody: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
                    .appContentWidth(820)
                    .accessibilityIdentifier("document-qa-screen")
            }
            .navigationTitle("Ask Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    versionMenu
                }
            }
        }
        .task(id: viewModel.selectedDocumentQuestionRevisionSelection) {
            await viewModel.loadDocumentQuestionAnswers()
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            questionComposer

            if viewModel.isLoadingDocumentQuestionAnswers {
                ProgressView("Loading saved answers...")
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else if viewModel.documentQuestionAnswers.isEmpty {
                AppEmptyState(
                    title: "No Saved Answers",
                    systemImage: "text.bubble",
                    description: "Ask a question to save a document-grounded answer for this version."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Saved Answers")
                            .font(.headline)
                        Spacer()
                        AppBadge(
                            text: viewModel.selectedDocumentQuestionRevisionSelection.displayName(for: viewModel.item),
                            tone: .info
                        )
                    }

                    ForEach(viewModel.documentQuestionAnswers) { questionAnswer in
                        DocumentQuestionAnswerRow(questionAnswer: questionAnswer)
                    }
                }
            }
        }
    }

    private var versionMenu: some View {
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

    private var questionComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask a Question")
                .font(.headline)

            TextField(
                "Ask something about this document",
                text: $viewModel.documentQuestionInput,
                axis: .vertical
            )
            .lineLimit(3...6)
            .disabled(viewModel.isSubmittingDocumentQuestion)

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
            .accessibilityIdentifier("submit-document-question")

            if let issueMessage = viewModel.documentQuestionAnswerIssueMessage {
                Text(issueMessage)
                    .font(.caption)
                    .foregroundStyle(AppStatusTone.warning.tint)
            }
        }
        .appCardStyle()
    }

    private func submitQuestion() {
        Task {
            await viewModel.submitDocumentQuestion()
        }
    }
}

private struct DocumentQuestionAnswerRow: View {
    let questionAnswer: DocumentQuestionAnswer

    private var statusTone: AppStatusTone {
        switch questionAnswer.responseKind {
        case .answered:
            return .info
        case .insufficientDocumentContent:
            return .warning
        }
    }

    private var statusLabel: String {
        switch questionAnswer.responseKind {
        case .answered:
            return "Document Answer"
        case .insufficientDocumentContent:
            return "Not Supported by Document"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AppBadge(text: statusLabel, tone: statusTone)
                Spacer()
                AppBadge(text: "v\(questionAnswer.sourceContentRevision)", tone: .neutral)
            }

            Text(questionAnswer.question)
                .font(.headline)

            Text(questionAnswer.answer)
                .foregroundStyle(.primary)

            Text(questionAnswer.timestamp, format: .dateTime.month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCardStyle()
    }
}
