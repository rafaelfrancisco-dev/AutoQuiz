import Foundation
import SwiftData
import Testing
@testable import AutoQuiz

@Suite(.serialized)
struct PersistenceMigrationTests {
    @Test
    func modelContainerBootUsesExpectedMigrationPlanAndSchemaVersion() throws {
        ItemMigrationPlan.validateLatestSchemaIsCurrent()

        let currentSchema = Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("AutoQuizMigrationTest.store")

        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let configuration = ModelConfiguration(nil, schema: currentSchema, url: storeURL)
        let container = try ModelContainer(
            for: currentSchema,
            migrationPlan: ItemMigrationPlan.self,
            configurations: configuration
        )

        guard let migrationPlan = container.migrationPlan else {
            Issue.record("ModelContainer did not attach a migration plan.")
            return
        }

        #expect(ObjectIdentifier(migrationPlan) == ObjectIdentifier(ItemMigrationPlan.self))
        #expect(container.schema.version == SchemaV4.versionIdentifier)
    }
    
    @Test
    func migrationFromSchemaV3ToSchemaV4PopulatesSourceContentRevision() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("AutoQuizMigrationV3ToV4.store")
        
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }
        
        // Seed a V3 store.
        try seedSchemaV3Store(at: storeURL)

        // Reopen using V4 + migration plan and assert revision fields are populated.
        do {
            let schemaV4 = Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)
            let configV4 = ModelConfiguration(nil, schema: schemaV4, url: storeURL)
            let migratedContainer = try ModelContainer(
                for: schemaV4,
                migrationPlan: ItemMigrationPlan.self,
                configurations: configV4
            )
            let context = ModelContext(migratedContainer)
            
            let migratedItems = try context.fetch(FetchDescriptor<Item>())
            let migratedAnswers = try context.fetch(FetchDescriptor<AnsweredQuestion>())
            let migratedSessions = try context.fetch(FetchDescriptor<QuizSession>())
            let migratedCards = try context.fetch(FetchDescriptor<SpacedRepetitionCard>())
            
            #expect(migratedItems.count == 1)
            #expect(migratedAnswers.count == 1)
            #expect(migratedSessions.count == 1)
            #expect(migratedCards.count == 1)
            
            #expect(migratedItems.first?.contentRevision == ContentRevisionPolicy.initialRevision)
            #expect(migratedItems.first?.contentRevisionUpdatedAt != nil)
            #expect(migratedAnswers.first?.sourceContentRevision == ContentRevisionPolicy.initialRevision)
            #expect(migratedSessions.first?.sourceContentRevision == ContentRevisionPolicy.initialRevision)
            #expect(migratedCards.first?.sourceContentRevision == ContentRevisionPolicy.initialRevision)
        }
    }
    
    private func seedSchemaV3Store(at storeURL: URL) throws {
        let schemaV3 = Schema(SchemaV3.models, version: SchemaV3.versionIdentifier)
        let configV3 = ModelConfiguration(nil, schema: schemaV3, url: storeURL)
        let container = try ModelContainer(for: schemaV3, configurations: configV3)
        let context = ModelContext(container)
        
        let item = ItemV3(timestamp: .now, content: "Legacy content")
        let answered = AnsweredQuestionV1(
            questionText: "Legacy question?",
            userAnswer: "Legacy answer",
            correctAnswer: "Legacy answer",
            isCorrect: true,
            pointsEarned: 10,
            questionType: .multipleChoice
        )
        item.answeredQuestions.append(answered)
        
        let session = QuizSessionV1(
            document: item,
            questionType: .multipleChoice,
            maxQuestions: 1,
            isUnlimitedQuestions: false,
            shuffleQuestions: false,
            includeFailedQuestions: false
        )
        
        let card = SpacedRepetitionCardV1(
            questionText: "Legacy card question?",
            answerText: "Legacy card answer",
            questionType: .multipleChoice,
            originalQuestionData: Data()
        )
        card.document = item
        
        context.insert(item)
        context.insert(answered)
        context.insert(session)
        context.insert(card)
        try context.save()
        
        #expect(try context.fetchCount(FetchDescriptor<ItemV3>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<AnsweredQuestionV1>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<QuizSessionV1>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SpacedRepetitionCardV1>()) == 1)
    }
}
