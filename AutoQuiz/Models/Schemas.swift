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
    
    var displayName: String {
        switch self {
        case .multipleChoice:
            return "Multiple Choice"
        case .trueFalse:
            return "True/False"
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
        [ItemV2.self, AnsweredQuestionV1.self]
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
            // Migration from V1 to V2: Remove totalPoints field
            // SwiftData will automatically handle field removal
            Logger.database.info("Starting migration from V1 to V2 - removing totalPoints field")
        },
        didMigrate: { context in
            Logger.database.info("Completed migration from V1 to V2")
        }
    )
}
