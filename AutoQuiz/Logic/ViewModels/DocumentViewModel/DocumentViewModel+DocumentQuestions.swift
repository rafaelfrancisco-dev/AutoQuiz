import Foundation
import SwiftUI
import OSLog

extension DocumentViewModel {
    var documentQuestionRevisionOptions: [ContentRevisionSelection] {
        var options: [ContentRevisionSelection] = [.current, .all]
        options.append(
            contentsOf: item.availableContentRevisions
                .filter { $0 != item.contentRevision }
                .map(ContentRevisionSelection.revision)
        )
        return options
    }

    var currentDocumentQuestionLanguageMode: Generator.QuizGenerationLanguageMode {
        resolvedGenerationLanguageMode ?? activeGenerationLanguageMode ?? defaultGenerationLanguageMode()
    }

    func loadDocumentQuestionAnswers() async {
        guard let appStore else {
            documentQuestionAnswers = documentQuestionAnswers
                .filter { questionAnswer in
                    let selectedRevision = selectedDocumentQuestionRevisionSelection.resolvedRevision(for: item)
                    return selectedRevision == nil || questionAnswer.sourceContentRevision == selectedRevision
                }
                .sorted { $0.timestamp > $1.timestamp }
            return
        }

        isLoadingDocumentQuestionAnswers = true
        defer { isLoadingDocumentQuestionAnswers = false }

        documentQuestionAnswers = await appStore.documentQuestionAnswers(
            documentID: item.id,
            sourceContentRevision: selectedDocumentQuestionRevisionSelection.resolvedRevision(for: item)
        )
    }

    func submitDocumentQuestion() async {
        let question = documentQuestionInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isSubmittingDocumentQuestion else { return }

        isSubmittingDocumentQuestion = true
        documentQuestionAnswerIssue = nil

        let languageMode = currentDocumentQuestionLanguageMode

        defer {
            isSubmittingDocumentQuestion = false
        }

        do {
            let result = try await documentAnswerProvider(question, languageMode)
            let savedQuestionAnswer = DocumentQuestionAnswer(
                documentID: item.id,
                question: question,
                answer: result.answer,
                responseKind: result.responseKind,
                sourceContentRevision: item.contentRevision
            )

            if let appStore {
                await appStore.saveDocumentQuestionAnswer(savedQuestionAnswer)
            }

            documentQuestionInput = ""

            if shouldIncludeDocumentQuestionAnswer(savedQuestionAnswer) {
                documentQuestionAnswers.insert(savedQuestionAnswer, at: 0)
                documentQuestionAnswers.sort { $0.timestamp > $1.timestamp }
            } else {
                await loadDocumentQuestionAnswers()
            }
        } catch let error as GeneratorError {
            Logger.error.error("Document question answering failed: \(error.userFacingMessage)")

            if error == .unsupportedLanguageOrLocale {
                pendingDocumentQuestionAfterFallback = question
                handleUnsupportedLanguage(for: languageMode)

                if pendingSupportedLanguages.isEmpty {
                    documentQuestionAnswerIssue = error
                }
                return
            }

            documentQuestionAnswerIssue = error
        } catch {
            Logger.error.error("Document question answering failed: \(error.localizedDescription)")
            documentQuestionAnswerIssue = .generationFailed
        }
    }

    private func shouldIncludeDocumentQuestionAnswer(_ questionAnswer: DocumentQuestionAnswer) -> Bool {
        switch selectedDocumentQuestionRevisionSelection {
        case .all:
            return true
        case .current:
            return questionAnswer.sourceContentRevision == item.contentRevision
        case .revision(let revision):
            return questionAnswer.sourceContentRevision == revision
        }
    }
}
