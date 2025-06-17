//
//  Item.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import SwiftData

typealias Item = ItemV2

enum Question: String, Codable, CaseIterable {
    case multipleChoice
    case trueFalse
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
            print("Starting migration from V1 to V2 - removing totalPoints field")
        },
        didMigrate: { context in
            print("Completed migration from V1 to V2")
        }
    )
}
