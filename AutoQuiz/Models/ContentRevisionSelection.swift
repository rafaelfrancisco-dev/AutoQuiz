//
//  ContentRevisionSelection.swift
//  AutoQuiz
//
//  Created by Codex on 20/02/2026.
//

import Foundation

enum ContentRevisionSelection: Hashable {
    case current
    case all
    case revision(Int)

    func resolvedRevision(for document: Item?) -> Int? {
        switch self {
        case .all:
            return nil
        case .current:
            return document?.contentRevision
        case .revision(let value):
            return value
        }
    }

    func displayName(for document: Item?) -> String {
        switch self {
        case .all:
            return "All Versions"
        case .current:
            if let revision = document?.contentRevision {
                return "Current (v\(revision))"
            }
            return "Current"
        case .revision(let value):
            return "Version \(value)"
        }
    }
}
