import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class AppStore {
    private(set) var items: [Item] = []
    private(set) var isReady = false
    private(set) var isBootstrapping = false
    private(set) var lastErrorMessage: String?

    private(set) var persistenceStore: AutoQuizStore?

    init(persistenceStore: AutoQuizStore? = nil) {
        self.persistenceStore = persistenceStore
        self.isReady = persistenceStore != nil
    }

    static func preview(items: [Item]) -> AppStore {
        let store = AppStore()
        store.items = items
        store.isReady = true
        return store
    }

    func bootstrap() async {
        guard !isReady, !isBootstrapping else { return }
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            let store = try await AutoQuizStore.openDefault()
            self.persistenceStore = store
            self.items = await store.items()
            self.isReady = true
        } catch {
            Logger.error.error("Failed to bootstrap AppStore: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func loadFixture(
        store: AutoQuizStore,
        items: [Item],
        quizSessions: [QuizSession] = [],
        spacedRepetitionCards: [SpacedRepetitionCard] = [],
        documentQuestionAnswers: [DocumentQuestionAnswer] = []
    ) async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            for item in items {
                try await store.upsertItem(item)
            }

            for session in quizSessions {
                try await store.upsertQuizSession(session)
            }

            for card in spacedRepetitionCards {
                try await store.upsertSpacedRepetitionCard(card)
            }

            for answer in documentQuestionAnswers {
                try await store.upsertDocumentQuestionAnswer(answer)
            }

            persistenceStore = store
            self.items = await store.items()
            isReady = true
            lastErrorMessage = nil
        } catch {
            Logger.error.error("Failed to load fixture data: \(error.localizedDescription)")
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshItems() async {
        guard let persistenceStore else { return }
        self.items = await persistenceStore.items()
    }

    func addItem(content: String) async {
        guard let persistenceStore else { return }

        let item = Item(timestamp: Date(), content: content)

        do {
            try await persistenceStore.upsertItem(item)
            await refreshItems()
        } catch {
            Logger.error.error("Failed to add item: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func saveItem(_ item: Item) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.upsertItem(item)
            await refreshItems()
        } catch {
            Logger.error.error("Failed to save item: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: Item) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.deleteItem(id: item.id)
            await refreshItems()
        } catch {
            Logger.error.error("Failed to delete item: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func saveAnsweredQuestion(_ answer: AnsweredQuestion) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.upsertAnsweredQuestion(answer)
            await refreshItems()
        } catch {
            Logger.error.error("Failed to save answered question: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func saveQuizSession(_ session: QuizSession) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.upsertQuizSession(session)
        } catch {
            Logger.error.error("Failed to save quiz session: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func saveSpacedRepetitionCard(_ card: SpacedRepetitionCard) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.upsertSpacedRepetitionCard(card)
        } catch {
            Logger.error.error("Failed to save card: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func saveSpacedRepetitionCards(_ cards: [SpacedRepetitionCard]) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.upsertSpacedRepetitionCards(cards)
        } catch {
            Logger.error.error("Failed to save cards: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func saveDocumentQuestionAnswer(_ questionAnswer: DocumentQuestionAnswer) async {
        guard let persistenceStore else { return }

        do {
            try await persistenceStore.upsertDocumentQuestionAnswer(questionAnswer)
        } catch {
            Logger.error.error("Failed to save document question answer: \(error.localizedDescription)")
            self.lastErrorMessage = error.localizedDescription
        }
    }

    func quizSessions(documentID: UUID? = nil, sourceContentRevision: Int? = nil) async -> [QuizSession] {
        guard let persistenceStore else { return [] }
        return await persistenceStore.quizSessions(documentID: documentID, sourceContentRevision: sourceContentRevision)
    }

    func spacedRepetitionCards(documentID: UUID? = nil, sourceContentRevision: Int? = nil) async -> [SpacedRepetitionCard] {
        guard let persistenceStore else { return [] }
        return await persistenceStore.spacedRepetitionCards(documentID: documentID, sourceContentRevision: sourceContentRevision)
    }

    func documentQuestionAnswers(documentID: UUID? = nil, sourceContentRevision: Int? = nil) async -> [DocumentQuestionAnswer] {
        guard let persistenceStore else { return [] }
        return await persistenceStore.documentQuestionAnswers(
            documentID: documentID,
            sourceContentRevision: sourceContentRevision
        )
    }
}
