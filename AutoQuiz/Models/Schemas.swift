//
//  Schemas.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation

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
