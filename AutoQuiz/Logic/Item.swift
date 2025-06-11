//
//  Item.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var content: String
    
    init(timestamp: Date, content: String) {
        self.timestamp = timestamp
        self.content = content
    }
}
