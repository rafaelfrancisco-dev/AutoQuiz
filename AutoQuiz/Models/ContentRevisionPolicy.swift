//
//  ContentRevisionPolicy.swift
//  AutoQuiz
//
//  Created by Codex on 20/02/2026.
//

import Foundation

enum ContentRevisionPolicy {
    static let initialRevision = 1

    static func normalized(_ revision: Int) -> Int {
        max(initialRevision, revision)
    }

    static func nextRevision(after current: Int) -> Int {
        normalized(current) + 1
    }
}

extension Item {
    var normalizedContentRevision: Int {
        ContentRevisionPolicy.normalized(contentRevision)
    }

    var availableContentRevisions: [Int] {
        let highestRevision = normalizedContentRevision
        return Array(ContentRevisionPolicy.initialRevision...highestRevision).reversed()
    }

    func appendContentAndAdvanceRevision(_ appendedContent: String) {
        let separator = content.hasSuffix("\n\n") ? "" : "\n\n"
        content += separator + appendedContent

        contentRevision = ContentRevisionPolicy.nextRevision(after: contentRevision)
        contentRevisionUpdatedAt = .now

        // Invalidate generated artifacts derived from the previous revision.
        questions.removeAll()
        trueFalseQuestions?.removeAll()
        title = nil
    }
}
