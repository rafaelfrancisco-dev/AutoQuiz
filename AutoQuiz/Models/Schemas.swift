//
//  Item.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import SwiftData
import OSLog

typealias Item = ItemV2
typealias AnsweredQuestion = AnsweredQuestionV1

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
        [ItemV2.self, AnsweredQuestionV1.self, QuizSession.self, SpacedRepetitionCard.self]
    }
}

// Migration plan
enum ItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Migration from V1 to V2: Remove totalPoints field, add QuizSession
            // SwiftData will automatically handle field removal and new model addition
            Logger.database.info("Starting migration from V1 to V2 - removing totalPoints field and adding QuizSession")
        },
        didMigrate: { context in
            Logger.database.info("Completed migration from V1 to V2")
        }
    )

    static func validateLatestSchemaIsCurrent(expectedLatestSchema: any VersionedSchema.Type = SchemaV2.self) {
        guard let latestSchema = schemas.last else {
            preconditionFailure("Migration plan has no schemas. Expected latest schema: \(expectedLatestSchema.versionIdentifier)")
        }

        precondition(
            ObjectIdentifier(latestSchema) == ObjectIdentifier(expectedLatestSchema),
            "Migration plan latest schema mismatch. Expected \(expectedLatestSchema.versionIdentifier), got \(latestSchema.versionIdentifier)"
        )
    }
}
