//
//  OSLog+Extensions.swift
//  AutoQuiz
//
//  Created by Claude Code on 17/06/2025.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    // MARK: - App Components
    
    /// Logger for database operations and migrations
    static let database = Logger(subsystem: subsystem, category: "database")
    
    /// Logger for document view model operations
    static let viewModel = Logger(subsystem: subsystem, category: "viewModel")
    
    /// Logger for background question generation
    static let generation = Logger(subsystem: subsystem, category: "generation")
    
    /// Logger for question answering and navigation
    static let quiz = Logger(subsystem: subsystem, category: "quiz")
    
    /// Logger for UI and general app events
    static let ui = Logger(subsystem: subsystem, category: "ui")
    
    /// Logger for error conditions
    static let error = Logger(subsystem: subsystem, category: "error")
}