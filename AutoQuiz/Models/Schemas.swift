//
//  Item.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import SwiftData
import OSLog

typealias Item = ItemV4
typealias AnsweredQuestion = AnsweredQuestionV2
typealias QuizSession = QuizSessionV2
typealias SpacedRepetitionCard = SpacedRepetitionCardV2

enum Question: String, Codable, CaseIterable {
    case multipleChoice
    case trueFalse
    case spacedRepetition

    var displayName: String {
        switch self {
        case .multipleChoice:
            return "Multiple Choice"
        case .trueFalse:
            return "True/False"
        case .spacedRepetition:
            return "Spaced Repetition"
        }
    }
}

// Schema versions for migration
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV1.self]
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV2.self, AnsweredQuestionV1.self, QuizSessionV1.self, SpacedRepetitionCardV1.self]
    }
}

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV3.self, AnsweredQuestionV1.self, QuizSessionV1.self, SpacedRepetitionCardV1.self]
    }
}

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV4.self, AnsweredQuestionV2.self, QuizSessionV2.self, SpacedRepetitionCardV2.self]
    }
}

// Migration plan
enum ItemMigrationPlan: SchemaMigrationPlan {
    private struct LegacyAnsweredSnapshot {
        let timestamp: Date
        let questionText: String
        let userAnswer: String
        let correctAnswer: String
        let isCorrect: Bool
        let pointsEarned: Int
        let questionType: Question
    }

    private struct LegacyItemSnapshot {
        let id: UUID
        let timestamp: Date
        let content: String
        let title: String?
        let questions: [MultipleChoiceQuestion]
        let trueFalseQuestions: [TrueFalseQuestion]?
        let preferredFallbackLanguageIdentifier: String?
        let answeredQuestions: [LegacyAnsweredSnapshot]
    }

    private struct LegacySessionSnapshot {
        let itemID: UUID?
        let id: UUID
        let sourceContentRevision: Int
        let startTime: Date
        let endTime: Date?
        let isCompleted: Bool
        let questionType: Question
        let maxQuestions: Int
        let isUnlimitedQuestions: Bool
        let shuffleQuestions: Bool
        let includeFailedQuestions: Bool
        let questionsAttempted: Int
        let questionsCorrect: Int
        let totalPointsEarned: Int
        let averageResponseTime: TimeInterval
        let questionResponses: [String]
    }

    private struct LegacyCardSnapshot {
        let itemID: UUID?
        let timestamp: Date
        let questionText: String
        let answerText: String
        let questionType: Question
        let originalQuestionData: Data
        let sourceContentRevision: Int
        let repetitionNumber: Int
        let easinessFactor: Double
        let intervalDays: Int
        let nextReviewDate: Date
        let isLearning: Bool
        let consecutiveCorrectAnswers: Int
        let totalReviews: Int
        let correctReviews: Int
        let lastReviewDate: Date?
        let averageResponseTime: TimeInterval
    }

    private struct LegacyV3Snapshot {
        let items: [LegacyItemSnapshot]
        let sessions: [LegacySessionSnapshot]
        let cards: [LegacyCardSnapshot]
    }

    private static var legacyV3Snapshot: LegacyV3Snapshot?

    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { _ in
            // Migration from V1 to V2: Remove totalPoints field, add QuizSession
            // SwiftData will automatically handle field removal and new model addition
            Logger.database.info("Starting migration from V1 to V2 - removing totalPoints field and adding QuizSession")
        },
        didMigrate: { _ in
            Logger.database.info("Completed migration from V1 to V2")
        }
    )

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { _ in
            Logger.database.info("Starting migration from V2 to V3 - adding preferred fallback language")
        },
        didMigrate: { _ in
            Logger.database.info("Completed migration from V2 to V3")
        }
    )

    static let migrateV3toV4 = MigrationStage.custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: { context in
            Logger.database.info("Starting migration from V3 to V4 - adding content revision tracking")

            do {
                let legacyItems = try context.fetch(FetchDescriptor<ItemV3>())
                var itemSnapshots: [LegacyItemSnapshot] = []
                var itemIDsByObjectID: [ObjectIdentifier: UUID] = [:]
                itemSnapshots.reserveCapacity(legacyItems.count)

                for item in legacyItems {
                    let syntheticID = UUID()
                    itemIDsByObjectID[ObjectIdentifier(item)] = syntheticID
                    let answeredSnapshots = item.answeredQuestions.map {
                        LegacyAnsweredSnapshot(
                            timestamp: $0.timestamp,
                            questionText: $0.questionText,
                            userAnswer: $0.userAnswer,
                            correctAnswer: $0.correctAnswer,
                            isCorrect: $0.isCorrect,
                            pointsEarned: $0.pointsEarned,
                            questionType: $0.questionType
                        )
                    }

                    itemSnapshots.append(
                        LegacyItemSnapshot(
                            id: syntheticID,
                            timestamp: item.timestamp,
                            content: item.content,
                            title: item.title,
                            questions: item.questions,
                            trueFalseQuestions: item.trueFalseQuestions,
                            preferredFallbackLanguageIdentifier: item.preferredFallbackLanguageIdentifier,
                            answeredQuestions: answeredSnapshots
                        )
                    )
                }

                let legacySessions = try context.fetch(FetchDescriptor<QuizSessionV1>())
                let sessionSnapshots = legacySessions.map { session in
                    let itemID = itemIDsByObjectID[ObjectIdentifier(session.document)]
                    return LegacySessionSnapshot(
                        itemID: itemID,
                        id: session.id,
                        sourceContentRevision: ContentRevisionPolicy.initialRevision,
                        startTime: session.startTime,
                        endTime: session.endTime,
                        isCompleted: session.isCompleted,
                        questionType: session.questionType,
                        maxQuestions: session.maxQuestions,
                        isUnlimitedQuestions: session.isUnlimitedQuestions,
                        shuffleQuestions: session.shuffleQuestions,
                        includeFailedQuestions: session.includeFailedQuestions,
                        questionsAttempted: session.questionsAttempted,
                        questionsCorrect: session.questionsCorrect,
                        totalPointsEarned: session.totalPointsEarned,
                        averageResponseTime: session.averageResponseTime,
                        questionResponses: session.questionResponses
                    )
                }

                let legacyCards = try context.fetch(FetchDescriptor<SpacedRepetitionCardV1>())
                let cardSnapshots = legacyCards.map { card in
                    let itemID = card.document.flatMap { itemIDsByObjectID[ObjectIdentifier($0)] }
                    return LegacyCardSnapshot(
                        itemID: itemID,
                        timestamp: card.timestamp,
                        questionText: card.questionText,
                        answerText: card.answerText,
                        questionType: card.questionType,
                        originalQuestionData: card.originalQuestionData,
                        sourceContentRevision: ContentRevisionPolicy.initialRevision,
                        repetitionNumber: card.repetitionNumber,
                        easinessFactor: card.easinessFactor,
                        intervalDays: card.intervalDays,
                        nextReviewDate: card.nextReviewDate,
                        isLearning: card.isLearning,
                        consecutiveCorrectAnswers: card.consecutiveCorrectAnswers,
                        totalReviews: card.totalReviews,
                        correctReviews: card.correctReviews,
                        lastReviewDate: card.lastReviewDate,
                        averageResponseTime: card.averageResponseTime
                    )
                }

                legacyV3Snapshot = LegacyV3Snapshot(
                    items: itemSnapshots,
                    sessions: sessionSnapshots,
                    cards: cardSnapshots
                )
            } catch {
                Logger.database.error("Failed to snapshot V3 data before migration: \(error.localizedDescription)")
                legacyV3Snapshot = LegacyV3Snapshot(items: [], sessions: [], cards: [])
            }
        },
        didMigrate: { context in
            do {
                let snapshot = legacyV3Snapshot ?? LegacyV3Snapshot(items: [], sessions: [], cards: [])
                legacyV3Snapshot = nil

                // Replace any auto-migrated rows with explicit reconstructed rows
                for item in try context.fetch(FetchDescriptor<ItemV4>()) {
                    context.delete(item)
                }
                for session in try context.fetch(FetchDescriptor<QuizSessionV2>()) {
                    context.delete(session)
                }
                for card in try context.fetch(FetchDescriptor<SpacedRepetitionCardV2>()) {
                    context.delete(card)
                }
                for answered in try context.fetch(FetchDescriptor<AnsweredQuestionV2>()) {
                    context.delete(answered)
                }

                var migratedItemsByID: [UUID: ItemV4] = [:]
                for legacyItem in snapshot.items {
                    let item = ItemV4(
                        timestamp: legacyItem.timestamp,
                        content: legacyItem.content,
                        contentRevision: ContentRevisionPolicy.initialRevision,
                        contentRevisionUpdatedAt: legacyItem.timestamp
                    )
                    item.title = legacyItem.title
                    item.questions = legacyItem.questions
                    item.trueFalseQuestions = legacyItem.trueFalseQuestions
                    item.preferredFallbackLanguageIdentifier = legacyItem.preferredFallbackLanguageIdentifier
                    context.insert(item)
                    migratedItemsByID[legacyItem.id] = item

                    for legacyAnswered in legacyItem.answeredQuestions {
                        let answered = AnsweredQuestionV2(
                            questionText: legacyAnswered.questionText,
                            userAnswer: legacyAnswered.userAnswer,
                            correctAnswer: legacyAnswered.correctAnswer,
                            isCorrect: legacyAnswered.isCorrect,
                            pointsEarned: legacyAnswered.pointsEarned,
                            questionType: legacyAnswered.questionType,
                            sourceContentRevision: ContentRevisionPolicy.initialRevision
                        )
                        answered.timestamp = legacyAnswered.timestamp
                        item.answeredQuestions.append(answered)
                        context.insert(answered)
                    }
                }

                for legacySession in snapshot.sessions {
                    guard let itemID = legacySession.itemID,
                          let migratedItem = migratedItemsByID[itemID] else { continue }
                    let session = QuizSessionV2(
                        document: migratedItem,
                        questionType: legacySession.questionType,
                        maxQuestions: legacySession.maxQuestions,
                        isUnlimitedQuestions: legacySession.isUnlimitedQuestions,
                        shuffleQuestions: legacySession.shuffleQuestions,
                        includeFailedQuestions: legacySession.includeFailedQuestions,
                        sourceContentRevision: legacySession.sourceContentRevision
                    )
                    session.id = legacySession.id
                    session.startTime = legacySession.startTime
                    session.endTime = legacySession.endTime
                    session.isCompleted = legacySession.isCompleted
                    session.questionsAttempted = legacySession.questionsAttempted
                    session.questionsCorrect = legacySession.questionsCorrect
                    session.totalPointsEarned = legacySession.totalPointsEarned
                    session.averageResponseTime = legacySession.averageResponseTime
                    session.questionResponses = legacySession.questionResponses
                    context.insert(session)
                }

                for legacyCard in snapshot.cards {
                    let migratedItem = legacyCard.itemID.flatMap { migratedItemsByID[$0] }
                    let card = SpacedRepetitionCardV2(
                        questionText: legacyCard.questionText,
                        answerText: legacyCard.answerText,
                        questionType: legacyCard.questionType,
                        originalQuestionData: legacyCard.originalQuestionData,
                        document: migratedItem,
                        sourceContentRevision: legacyCard.sourceContentRevision
                    )
                    card.timestamp = legacyCard.timestamp
                    card.repetitionNumber = legacyCard.repetitionNumber
                    card.easinessFactor = legacyCard.easinessFactor
                    card.intervalDays = legacyCard.intervalDays
                    card.nextReviewDate = legacyCard.nextReviewDate
                    card.isLearning = legacyCard.isLearning
                    card.consecutiveCorrectAnswers = legacyCard.consecutiveCorrectAnswers
                    card.totalReviews = legacyCard.totalReviews
                    card.correctReviews = legacyCard.correctReviews
                    card.lastReviewDate = legacyCard.lastReviewDate
                    card.averageResponseTime = legacyCard.averageResponseTime
                    context.insert(card)
                }

                try context.save()
                Logger.database.info("Completed migration from V3 to V4")
            } catch {
                Logger.database.error("Failed migration from V3 to V4: \(error.localizedDescription)")
            }
        }
    )

    static func validateLatestSchemaIsCurrent(expectedLatestSchema: any VersionedSchema.Type = SchemaV4.self) {
        guard let latestSchema = schemas.last else {
            preconditionFailure("Migration plan has no schemas. Expected latest schema: \(expectedLatestSchema.versionIdentifier)")
        }

        precondition(
            ObjectIdentifier(latestSchema) == ObjectIdentifier(expectedLatestSchema),
            "Migration plan latest schema mismatch. Expected \(expectedLatestSchema.versionIdentifier), got \(latestSchema.versionIdentifier)"
        )
    }
}
