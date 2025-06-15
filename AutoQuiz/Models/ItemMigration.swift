//
//  ItemMigration.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 15/06/2025.
//

import Foundation
import SwiftData

enum ItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [ItemSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}

enum ItemSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Item.self]
    }
}
