import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class AppStore {
    private(set) var items: [Item] = []
    private(set) var isReady = false
    private(set) var lastErrorMessage: String?

    private(set) var persistenceStore: AutoQuizStore?

    func bootstrap() async {
        guard !isReady else { return }

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

    func quizSessions(documentID: UUID? = nil, sourceContentRevision: Int? = nil) async -> [QuizSession] {
        guard let persistenceStore else { return [] }
        return await persistenceStore.quizSessions(documentID: documentID, sourceContentRevision: sourceContentRevision)
    }

    func spacedRepetitionCards(documentID: UUID? = nil, sourceContentRevision: Int? = nil) async -> [SpacedRepetitionCard] {
        guard let persistenceStore else { return [] }
        return await persistenceStore.spacedRepetitionCards(documentID: documentID, sourceContentRevision: sourceContentRevision)
    }
}
