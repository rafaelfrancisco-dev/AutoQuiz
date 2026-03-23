import Foundation

enum PreviewData {
    static let sampleItemID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let emptyItemID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    static func sampleItem() -> Item {
        let item = Item(
            id: sampleItemID,
            timestamp: .now.addingTimeInterval(-86_400 * 3),
            content: """
            SwiftUI builds native interfaces across Apple platforms. AutoQuiz helps turn study material into quizzes, analytics, and review sessions.
            """
        )
        item.title = "SwiftUI Study Notes"
        item.questions = [
            MultipleChoiceQuestion(
                question: "Which view type replaces NavigationView in modern SwiftUI?",
                options: ["NavigationSplitView", "NavigationStack", "TabView", "Group"],
                answer: "NavigationStack"
            ),
            MultipleChoiceQuestion(
                question: "Which modifier is preferred over foregroundColor in newer SwiftUI code?",
                options: ["foregroundStyle", "tint", "blendMode", "fill"],
                answer: "foregroundStyle"
            )
        ]
        item.trueFalseQuestions = [
            TrueFalseQuestion(
                question: "NavigationStack is the modern replacement for NavigationView.",
                isTrue: true
            )
        ]
        item.answeredQuestions = [
            AnsweredQuestion(
                itemID: item.id,
                questionText: "Which view type replaces NavigationView in modern SwiftUI?",
                userAnswer: "NavigationStack",
                correctAnswer: "NavigationStack",
                isCorrect: true,
                pointsEarned: 10,
                questionType: .multipleChoice,
                sourceContentRevision: item.contentRevision
            ),
            AnsweredQuestion(
                itemID: item.id,
                questionText: "NavigationStack is the modern replacement for NavigationView.",
                userAnswer: "False",
                correctAnswer: "True",
                isCorrect: false,
                pointsEarned: 0,
                questionType: .trueFalse,
                sourceContentRevision: item.contentRevision
            )
        ]
        return item
    }

    static func emptyItem() -> Item {
        let item = Item(id: emptyItemID, timestamp: .now, content: "Fresh content without generated questions yet.")
        item.title = "Empty Preview Document"
        return item
    }

    static func sampleQuizSessions(for item: Item) -> [QuizSession] {
        (0..<6).map { index in
            let session = QuizSession(
                documentID: item.id,
                questionType: index.isMultiple(of: 2) ? .multipleChoice : .trueFalse,
                maxQuestions: 10,
                isUnlimitedQuestions: false,
                shuffleQuestions: true,
                includeFailedQuestions: false,
                sourceContentRevision: item.contentRevision
            )
            session.startTime = Calendar.current.date(byAdding: .day, value: -(5 - index), to: .now) ?? .now
            session.questionsAttempted = 10
            session.questionsCorrect = 6 + index % 4
            session.totalPointsEarned = session.questionsCorrect * 10
            session.averageResponseTime = 11 + Double(index)
            session.questionResponses = ["One", "Two", "Three"]
            session.completeSession()
            return session
        }
    }

    static func sampleDocumentAnswers(for item: Item) -> [DocumentQuestionAnswer] {
        [
            DocumentQuestionAnswer(
                documentID: item.id,
                question: "What does SwiftUI replace?",
                answer: "It replaces older imperative UI construction with a declarative approach.",
                responseKind: .answered,
                timestamp: .now.addingTimeInterval(-2_400),
                sourceContentRevision: item.contentRevision
            ),
            DocumentQuestionAnswer(
                documentID: item.id,
                question: "Does the document explain UIKit internals?",
                answer: "The document does not provide enough detail to answer that.",
                responseKind: .insufficientDocumentContent,
                timestamp: .now.addingTimeInterval(-1_200),
                sourceContentRevision: item.contentRevision
            )
        ]
    }

    static func sampleSpacedRepetitionCards(for item: Item) -> [SpacedRepetitionCard] {
        let cards = [
            SpacedRepetitionCard(
                questionText: "Which container is used for type-safe navigation?",
                answerText: "NavigationStack",
                questionType: .multipleChoice,
                originalQuestionData: Data(),
                documentID: item.id,
                sourceContentRevision: item.contentRevision
            ),
            SpacedRepetitionCard(
                questionText: "SwiftUI uses declarative UI.",
                answerText: "True",
                questionType: .trueFalse,
                originalQuestionData: Data(),
                documentID: item.id,
                sourceContentRevision: item.contentRevision
            )
        ]
        cards[0].review(quality: 5, responseTime: 2.1)
        cards[0].review(quality: 4, responseTime: 2.7)
        cards[1].review(quality: 2, responseTime: 4.9)
        cards[0].nextReviewDate = .now.addingTimeInterval(-600)
        cards[1].nextReviewDate = .now.addingTimeInterval(-1_200)
        return cards
    }
}
