import Foundation
import OSLog
import Wax
import WaxCore

actor AutoQuizStore {
    private let wax: Wax
    private let session: WaxSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var itemFramesByID: [UUID: UInt64] = [:]
    private var answerFramesByID: [UUID: UInt64] = [:]
    private var sessionFramesByID: [UUID: UInt64] = [:]
    private var cardFramesByID: [UUID: UInt64] = [:]

    private var itemsByID: [UUID: Item] = [:]
    private var answersByID: [UUID: AnsweredQuestion] = [:]
    private var sessionsByID: [UUID: QuizSession] = [:]
    private var cardsByID: [UUID: SpacedRepetitionCard] = [:]

    static func openDefault() async throws -> AutoQuizStore {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = appSupport.appendingPathComponent("AutoQuiz", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("autoquiz.mv2s")
        return try await open(at: storeURL)
    }

    static func open(at storeURL: URL) async throws -> AutoQuizStore {
        let directory = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        Logger.database.notice("Using Wax store at \(storeURL.path, privacy: .public)")

        let wax: Wax
        if FileManager.default.fileExists(atPath: storeURL.path) {
            wax = try await Wax.open(at: storeURL)
        } else {
            wax = try await Wax.create(at: storeURL)
        }

        let session = try await wax.openSession(
            .readWrite(.wait),
            config: .init(
                enableTextSearch: true,
                enableVectorSearch: false,
                enableStructuredMemory: false
            )
        )

        let store = AutoQuizStore(wax: wax, session: session)
        try await store.loadFromDisk()
        return store
    }

    private init(wax: Wax, session: WaxSession) {
        self.wax = wax
        self.session = session
    }

    func close() async {
        await session.close()
        try? await wax.close()
    }

    deinit {
        let session = session
        let wax = wax
        Task {
            await session.close()
            try? await wax.close()
        }
    }

    func items() -> [Item] {
        itemsByID.values.sorted { $0.timestamp > $1.timestamp }
    }

    func quizSessions(documentID: UUID? = nil, sourceContentRevision: Int? = nil) -> [QuizSession] {
        sessionsByID.values.filter { session in
            let matchesDocument = documentID == nil || session.documentID == documentID
            let matchesRevision = sourceContentRevision == nil || session.sourceContentRevision == sourceContentRevision
            return matchesDocument && matchesRevision
        }
        .sorted { $0.startTime < $1.startTime }
    }

    func spacedRepetitionCards(documentID: UUID? = nil, sourceContentRevision: Int? = nil) -> [SpacedRepetitionCard] {
        cardsByID.values.filter { card in
            let matchesDocument = documentID == nil || card.documentID == documentID
            let matchesRevision = sourceContentRevision == nil || card.sourceContentRevision == sourceContentRevision
            return matchesDocument && matchesRevision
        }
    }

    func upsertItem(_ item: Item) async throws {
        let previousFrame = itemFramesByID[item.id]
        let frameID = try await persist(
            entityType: .item,
            entityID: item.id,
            object: item,
            previousFrameID: previousFrame,
            metadata: [
                WaxMetadataKeys.contentRevision: String(item.contentRevision)
            ],
            searchText: [item.title ?? "", item.content].joined(separator: "\n")
        )

        itemFramesByID[item.id] = frameID
        itemsByID[item.id] = item
    }

    func deleteItem(id: UUID) async throws {
        guard let frameID = itemFramesByID[id] else { return }
        try await wax.delete(frameId: frameID)
        try await session.removeText(frameId: frameID)
        try await session.commit()

        itemFramesByID.removeValue(forKey: id)
        itemsByID.removeValue(forKey: id)

        let answersToDelete = answersByID.values.filter { $0.itemID == id }.map(\.id)
        for answerID in answersToDelete {
            try await deleteAnsweredQuestion(id: answerID)
        }

        let sessionsToDelete = sessionsByID.values.filter { $0.documentID == id }.map(\.id)
        for sessionID in sessionsToDelete {
            try await deleteQuizSession(id: sessionID)
        }

        let cardsToDelete = cardsByID.values.filter { $0.documentID == id }.map(\.id)
        for cardID in cardsToDelete {
            try await deleteSpacedRepetitionCard(id: cardID)
        }
    }

    func upsertAnsweredQuestion(_ answer: AnsweredQuestion) async throws {
        let previousFrame = answerFramesByID[answer.id]
        let frameID = try await persist(
            entityType: .answeredQuestion,
            entityID: answer.id,
            object: answer,
            previousFrameID: previousFrame,
            metadata: [
                WaxMetadataKeys.itemID: answer.itemID.uuidString,
                WaxMetadataKeys.contentRevision: String(answer.sourceContentRevision)
            ],
            searchText: [answer.questionText, answer.userAnswer, answer.correctAnswer].joined(separator: "\n")
        )

        answerFramesByID[answer.id] = frameID
        answersByID[answer.id] = answer

        if let item = itemsByID[answer.itemID] {
            if let index = item.answeredQuestions.firstIndex(where: { $0.id == answer.id }) {
                item.answeredQuestions[index] = answer
            } else {
                item.answeredQuestions.append(answer)
            }
        }
    }

    func upsertQuizSession(_ quizSession: QuizSession) async throws {
        let previousFrame = sessionFramesByID[quizSession.id]
        let frameID = try await persist(
            entityType: .quizSession,
            entityID: quizSession.id,
            object: quizSession,
            previousFrameID: previousFrame,
            metadata: [
                WaxMetadataKeys.itemID: quizSession.documentID.uuidString,
                WaxMetadataKeys.contentRevision: String(quizSession.sourceContentRevision)
            ],
            searchText: quizSession.questionResponses.joined(separator: "\n")
        )

        sessionFramesByID[quizSession.id] = frameID
        sessionsByID[quizSession.id] = quizSession
    }

    func upsertSpacedRepetitionCard(_ card: SpacedRepetitionCard) async throws {
        let previousFrame = cardFramesByID[card.id]
        var metadata: [String: String] = [
            WaxMetadataKeys.contentRevision: String(card.sourceContentRevision)
        ]
        if let documentID = card.documentID {
            metadata[WaxMetadataKeys.itemID] = documentID.uuidString
        }

        let frameID = try await persist(
            entityType: .spacedRepetitionCard,
            entityID: card.id,
            object: card,
            previousFrameID: previousFrame,
            metadata: metadata,
            searchText: [card.questionText, card.answerText].joined(separator: "\n")
        )

        cardFramesByID[card.id] = frameID
        cardsByID[card.id] = card
    }

    func upsertSpacedRepetitionCards(_ cards: [SpacedRepetitionCard]) async throws {
        for card in cards {
            try await upsertSpacedRepetitionCard(card)
        }
    }

    private func persist<T: Codable>(
        entityType: WaxEntityType,
        entityID: UUID,
        object: T,
        previousFrameID: UInt64?,
        metadata: [String: String],
        searchText: String
    ) async throws -> UInt64 {
        let payload = try encoder.encode(object)
        let envelope = WaxEntityEnvelope(
            entityType: entityType,
            entityID: entityID,
            payload: payload
        )
        let bytes = try encoder.encode(envelope)

        var fullMetadata = metadata
        fullMetadata[WaxMetadataKeys.entityType] = entityType.rawValue
        fullMetadata[WaxMetadataKeys.entityID] = entityID.uuidString

        let frameID = try await session.put(
            bytes,
            options: FrameMetaSubset(
                kind: "autoquiz.\(entityType.rawValue)",
                searchText: searchText,
                metadata: Metadata(fullMetadata)
            )
        )

        try await session.indexText(frameId: frameID, text: searchText)

        if let previousFrameID {
            try await wax.supersede(supersededId: previousFrameID, supersedingId: frameID)
        }

        try await session.commit()
        return frameID
    }

    private func loadFromDisk() async throws {
        let metas = await wax.frameMetas().sorted { $0.id < $1.id }

        for meta in metas {
            guard meta.supersededBy == nil,
                  meta.status == .active,
                  let metadata = meta.metadata?.entries,
                  let typeValue = metadata[WaxMetadataKeys.entityType],
                  let entityType = WaxEntityType(rawValue: typeValue),
                  let entityIDString = metadata[WaxMetadataKeys.entityID],
                  let entityID = UUID(uuidString: entityIDString)
            else {
                continue
            }

            let content = try await wax.frameContent(frameId: meta.id)
            let envelope = try decoder.decode(WaxEntityEnvelope.self, from: content)

            switch entityType {
            case .item:
                let item = try decoder.decode(Item.self, from: envelope.payload)
                itemFramesByID[entityID] = meta.id
                itemsByID[entityID] = item
            case .answeredQuestion:
                let answer = try decoder.decode(AnsweredQuestion.self, from: envelope.payload)
                answerFramesByID[entityID] = meta.id
                answersByID[entityID] = answer
            case .quizSession:
                let session = try decoder.decode(QuizSession.self, from: envelope.payload)
                sessionFramesByID[entityID] = meta.id
                sessionsByID[entityID] = session
            case .spacedRepetitionCard:
                let card = try decoder.decode(SpacedRepetitionCard.self, from: envelope.payload)
                cardFramesByID[entityID] = meta.id
                cardsByID[entityID] = card
            }
        }

        for item in itemsByID.values {
            item.answeredQuestions = answersByID.values
                .filter { $0.itemID == item.id }
                .sorted { $0.timestamp > $1.timestamp }
        }
    }

    private func deleteAnsweredQuestion(id: UUID) async throws {
        guard let frameID = answerFramesByID[id] else { return }
        try await wax.delete(frameId: frameID)
        try await session.removeText(frameId: frameID)
        try await session.commit()
        answerFramesByID.removeValue(forKey: id)
        answersByID.removeValue(forKey: id)
    }

    private func deleteQuizSession(id: UUID) async throws {
        guard let frameID = sessionFramesByID[id] else { return }
        try await wax.delete(frameId: frameID)
        try await session.removeText(frameId: frameID)
        try await session.commit()
        sessionFramesByID.removeValue(forKey: id)
        sessionsByID.removeValue(forKey: id)
    }

    private func deleteSpacedRepetitionCard(id: UUID) async throws {
        guard let frameID = cardFramesByID[id] else { return }
        try await wax.delete(frameId: frameID)
        try await session.removeText(frameId: frameID)
        try await session.commit()
        cardFramesByID.removeValue(forKey: id)
        cardsByID.removeValue(forKey: id)
    }
}
