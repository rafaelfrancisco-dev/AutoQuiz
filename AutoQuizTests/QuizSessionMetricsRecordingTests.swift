//
//  QuizSessionMetricsRecordingTests.swift
//  AutoQuizTests
//
//  Created by Codex on 19/02/2026.
//

import Testing
import Foundation
@testable import AutoQuiz

struct QuizSessionMetricsRecordingTests {
    @Test
    func multipleChoiceAnswerRecordsQuizSessionMetrics() throws {
        let item = Item(timestamp: .now, content: "Test content")
        let question = MultipleChoiceQuestion(
            question: "What is 2 + 2?",
            options: ["1", "2", "3", "4"],
            anwswer: "4"
        )
        item.questions = [question]
        
        let viewModel = DocumentViewModel(item: item)
        viewModel.startQuiz(with: QuizSettings(
            questionType: .multipleChoice,
            maxQuestions: 1,
            includeFailedQuestions: false,
            shuffleQuestions: false,
            useOriginalLanguage: true,
            allowSkipQuestions: false
        ))
        
        viewModel.currentQuestionStartedAt = Date().addingTimeInterval(-1.0)
        viewModel.answeredQuestion(question: question, correct: true, userAnswer: "4")
        
        let session = try #require(viewModel.currentQuizSession)
        #expect(session.questionsAttempted == 1)
        #expect(session.questionsCorrect == 1)
        #expect(session.totalPointsEarned == 10)
        #expect(session.questionResponses == ["What is 2 + 2?"])
        #expect(session.averageResponseTime >= 0)
    }
    
    @Test
    func trueFalseAnswerRecordsQuizSessionMetrics() throws {
        let item = Item(timestamp: .now, content: "Test content")
        let question = TrueFalseQuestion(
            question: "Swift is a programming language.",
            isTrue: true
        )
        item.trueFalseQuestions = [question]
        
        let viewModel = DocumentViewModel(item: item)
        viewModel.startQuiz(with: QuizSettings(
            questionType: .trueFalse,
            maxQuestions: 1,
            includeFailedQuestions: false,
            shuffleQuestions: false,
            useOriginalLanguage: true,
            allowSkipQuestions: false
        ))
        
        viewModel.currentQuestionStartedAt = Date().addingTimeInterval(-1.0)
        viewModel.answeredTrueFalseQuestion(question: question, correct: false, userAnswer: false)
        
        let session = try #require(viewModel.currentQuizSession)
        #expect(session.questionsAttempted == 1)
        #expect(session.questionsCorrect == 0)
        #expect(session.totalPointsEarned == 0)
        #expect(session.questionResponses == ["Swift is a programming language."])
        #expect(session.averageResponseTime >= 0)
    }
}
