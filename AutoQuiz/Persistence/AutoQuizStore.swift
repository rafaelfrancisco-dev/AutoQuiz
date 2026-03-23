import Foundation
import OSLog
import Wax
import WaxCore

actor AutoQuizStore {
    private let wax: Wax
    private let session: WaxSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let embedder = NLEmbeddingProvider()

    private var itemFramesByID: [UUID: UInt64] = [:]
    private var answerFramesByID: [UUID: UInt64] = [:]
    private var sessionFramesByID: [UUID: UInt64] = [:]
    private var cardFramesByID: [UUID: UInt64] = [:]
    private var documentQuestionAnswerFramesByID: [UUID: UInt64] = [:]
    private var chunkFramesByDocumentID: [UUID: [UInt64]] = [:]
    private var embeddingLanguageByDocumentID: [UUID: NLLanguage] = [:]
    private var onIndexingStateChanged: (@Sendable (Bool) -> Void)?

    private var itemsByID: [UUID: Item] = [:]
    private var answersByID: [UUID: AnsweredQuestion] = [:]
    private var sessionsByID: [UUID: QuizSession] = [:]
    private var cardsByID: [UUID: SpacedRepetitionCard] = [:]
    private var documentQuestionAnswersByID: [UUID: DocumentQuestionAnswer] = [:]

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
                enableVectorSearch: true,
                enableStructuredMemory: true,
                vectorDimensions: NLEmbeddingProvider().dimensions
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

    func documentQuestionAnswers(documentID: UUID? = nil, sourceContentRevision: Int? = nil) -> [DocumentQuestionAnswer] {
        documentQuestionAnswersByID.values.filter { questionAnswer in
            let matchesDocument = documentID == nil || questionAnswer.documentID == documentID
            let matchesRevision = sourceContentRevision == nil || questionAnswer.sourceContentRevision == sourceContentRevision
            return matchesDocument && matchesRevision
        }
        .sorted { $0.timestamp > $1.timestamp }
    }

    func upsertItem(_ item: Item) async throws {
        let previousRevision = itemsByID[item.id]?.contentRevision
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

        if previousRevision != item.contentRevision {
            Task { await self.indexDocumentChunks(item: item) }
        }
    }

    func deleteItem(id: UUID) async throws {
        guard let frameID = itemFramesByID[id] else { return }
        try await wax.delete(frameId: frameID)
        try await session.removeText(frameId: frameID)
        try await session.commit()

        itemFramesByID.removeValue(forKey: id)
        itemsByID.removeValue(forKey: id)

        if let chunkFrameIDs = chunkFramesByDocumentID[id] {
            for chunkFrameID in chunkFrameIDs {
                try? await wax.delete(frameId: chunkFrameID)
            }
            chunkFramesByDocumentID.removeValue(forKey: id)
        }

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

        let questionAnswersToDelete = documentQuestionAnswersByID.values
            .filter { $0.documentID == id }
            .map(\.id)
        for questionAnswerID in questionAnswersToDelete {
            try await deleteDocumentQuestionAnswer(id: questionAnswerID)
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

    func upsertDocumentQuestionAnswer(_ questionAnswer: DocumentQuestionAnswer) async throws {
        let previousFrame = documentQuestionAnswerFramesByID[questionAnswer.id]
        let frameID = try await persist(
            entityType: .documentQuestionAnswer,
            entityID: questionAnswer.id,
            object: questionAnswer,
            previousFrameID: previousFrame,
            metadata: [
                WaxMetadataKeys.itemID: questionAnswer.documentID.uuidString,
                WaxMetadataKeys.contentRevision: String(questionAnswer.sourceContentRevision)
            ],
            searchText: [questionAnswer.question, questionAnswer.answer].joined(separator: "\n")
        )

        documentQuestionAnswerFramesByID[questionAnswer.id] = frameID
        documentQuestionAnswersByID[questionAnswer.id] = questionAnswer
    }

    func setOnIndexingStateChanged(_ callback: @escaping @Sendable (Bool) -> Void) {
        onIndexingStateChanged = callback
    }

    // MARK: - Vector Search

    func searchDocumentContent(query: String, documentID: UUID, topK: Int = 5) async throws -> [String] {
        let embeddingLanguage = embeddingLanguageByDocumentID[documentID] ?? .english
        let queryVector = try await embedder.embed(query, language: embeddingLanguage)
        let request = SearchRequest(
            embedding: queryVector,
            mode: .vectorOnly,
            topK: topK * 2,
            frameFilter: FrameFilter(
                metadataFilter: MetadataFilter(
                    requiredEntries: [WaxMetadataKeys.chunkDocumentID: documentID.uuidString]
                )
            )
        )
        let response = try await session.search(request)

        var chunks: [String] = []
        for result in response.results.prefix(topK) {
            if let content = try? await wax.frameContent(frameId: result.frameId),
               let text = String(data: content, encoding: .utf8) {
                chunks.append(text)
            }
        }
        Logger.generation.debug("Semantic search returned \(chunks.count) chunks for document Q&A")
        return chunks
    }

    // MARK: - Structured Memory

    func assertDocumentFacts(item: Item, title: String?, detectedLanguage: String?) async {
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let entityKey = EntityKey("doc:\(item.id.uuidString)")

        do {
            let aliases = [title].compactMap { $0 }
            _ = try await session.upsertEntity(key: entityKey, kind: "document", aliases: aliases, nowMs: nowMs)

            let timeRange = StructuredTimeRange(fromMs: nowMs, toMs: nil)
            let evidence = StructuredEvidence(
                sourceFrameId: itemFramesByID[item.id] ?? 0,
                extractorId: "autoquiz",
                extractorVersion: "1",
                assertedAtMs: nowMs
            )

            if let title {
                _ = try await session.assertFact(
                    subject: entityKey,
                    predicate: PredicateKey("title"),
                    object: .string(title),
                    valid: timeRange,
                    system: timeRange,
                    evidence: [evidence]
                )
            }

            _ = try await session.assertFact(
                subject: entityKey,
                predicate: PredicateKey("contentRevision"),
                object: .int(Int64(item.contentRevision)),
                valid: timeRange,
                system: timeRange,
                evidence: [evidence]
            )

            if let lang = detectedLanguage {
                _ = try await session.assertFact(
                    subject: entityKey,
                    predicate: PredicateKey("language"),
                    object: .string(lang),
                    valid: timeRange,
                    system: timeRange,
                    evidence: [evidence]
                )
            }

            try await session.commit()
            Logger.database.debug("Asserted structured facts for document \(item.id.uuidString, privacy: .public)")
        } catch {
            Logger.database.warning("Failed to assert document facts: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func indexDocumentChunks(item: Item) async {
        onIndexingStateChanged?(true)
        defer { onIndexingStateChanged?(false) }

        if let oldFrameIDs = chunkFramesByDocumentID[item.id] {
            for frameID in oldFrameIDs {
                try? await wax.delete(frameId: frameID)
            }
            chunkFramesByDocumentID.removeValue(forKey: item.id)
        }

        let trimmedContent = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        let detectedLanguage = NLLanguageRecognizer.dominantLanguage(for: trimmedContent) ?? .english
        embeddingLanguageByDocumentID[item.id] = detectedLanguage
        Logger.generation.debug("Detected embedding language '\(detectedLanguage.rawValue, privacy: .public)' for document \(item.id.uuidString, privacy: .public)")

        let chunks = trimmedContent.chunked(into: 2000)
        var newFrameIDs: [UInt64] = []

        for (index, chunk) in chunks.enumerated() {
            guard let chunkData = chunk.data(using: .utf8) else { continue }
            do {
                let vector = try await embedder.embed(chunk, language: detectedLanguage)
                let frameID = try await session.put(
                    chunkData,
                    embedding: vector,
                    options: FrameMetaSubset(
                        kind: "autoquiz.document_chunk",
                        metadata: Metadata([
                            WaxMetadataKeys.entityType: "document_chunk",
                            WaxMetadataKeys.chunkDocumentID: item.id.uuidString,
                            WaxMetadataKeys.chunkRevision: String(item.contentRevision),
                            WaxMetadataKeys.chunkEmbeddingLanguage: detectedLanguage.rawValue
                        ])
                    )
                )
                newFrameIDs.append(frameID)
            } catch {
                Logger.generation.warning("Failed to index document chunk \(index): \(error.localizedDescription)")
            }
        }

        if !newFrameIDs.isEmpty {
            do {
                try await session.commit()
                chunkFramesByDocumentID[item.id] = newFrameIDs
                Logger.generation.debug("Indexed \(newFrameIDs.count) chunks for document \(item.id.uuidString, privacy: .public)")
            } catch {
                Logger.database.warning("Failed to commit chunk embeddings: \(error.localizedDescription)")
            }
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
            guard meta.supersededBy == nil, meta.status == .active else { continue }
            guard let metadata = meta.metadata?.entries,
                  let typeValue = metadata[WaxMetadataKeys.entityType] else { continue }

            if typeValue == "document_chunk" {
                if let docIDString = metadata[WaxMetadataKeys.chunkDocumentID],
                   let docID = UUID(uuidString: docIDString) {
                    chunkFramesByDocumentID[docID, default: []].append(meta.id)
                    if let langValue = metadata[WaxMetadataKeys.chunkEmbeddingLanguage] {
                        embeddingLanguageByDocumentID[docID] = NLLanguage(langValue)
                    }
                }
                continue
            }

            guard let entityType = WaxEntityType(rawValue: typeValue),
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
            case .documentQuestionAnswer:
                let questionAnswer = try decoder.decode(DocumentQuestionAnswer.self, from: envelope.payload)
                documentQuestionAnswerFramesByID[entityID] = meta.id
                documentQuestionAnswersByID[entityID] = questionAnswer
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

    private func deleteDocumentQuestionAnswer(id: UUID) async throws {
        guard let frameID = documentQuestionAnswerFramesByID[id] else { return }
        try await wax.delete(frameId: frameID)
        try await session.removeText(frameId: frameID)
        try await session.commit()
        documentQuestionAnswerFramesByID.removeValue(forKey: id)
        documentQuestionAnswersByID.removeValue(forKey: id)
    }
}
