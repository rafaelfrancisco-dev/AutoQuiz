//
//  Item.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import SwiftData

typealias Item = ItemV1

enum Question: String, Codable, CaseIterable {
    case multipleChoice
    case trueFalse
}

// Schema versions for migration
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Item.self]
    }
}

// Migration plan
enum ItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
        // Add future versions here: SchemaV2.self, etc.
    }
    
    static var stages: [MigrationStage] {
        // Add migration stages here when needed
        []
    }
}
