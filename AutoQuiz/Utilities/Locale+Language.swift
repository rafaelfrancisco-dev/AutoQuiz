//
//  Locale+Language.swift
//  AutoQuiz
//
//  Created by Codex on 20/02/2026.
//

import Foundation

extension Locale.Language {
    var persistedIdentifier: String {
        minimalIdentifier
    }
    
    var displayIdentifier: String {
        languageCode?.identifier ?? minimalIdentifier
    }
}
