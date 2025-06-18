//
//  DocumentViewModel+QuestionAnswering.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI
import OSLog

extension DocumentViewModel {
    func answeredQuestion(question: MultipleChoiceQuestion, correct: Bool, userAnswer: String) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestionV1(
            questionText: question.question,
            userAnswer: userAnswer,
            correctAnswer: question.anwswer,
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .multipleChoice
        )
        
        recordAnswer(answeredQuestion)
        
        // Auto-advance after 1 second delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            handleAutoAdvanceAfterAnswer()
        }
    }
    
    func answeredTrueFalseQuestion(question: TrueFalseQuestion, correct: Bool, userAnswer: Bool) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestionV1(
            questionText: question.question,
            userAnswer: userAnswer ? "True" : "False",
            correctAnswer: question.isTrue ? "True" : "False",
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .trueFalse
        )
        
        recordAnswer(answeredQuestion)
        
        // Auto-advance after 1 second delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            handleAutoAdvanceAfterAnswer()
        }
    }
    
    private func recordAnswer(_ answeredQuestion: AnsweredQuestionV1) {
        currentSessionAnsweredQuestions.append(answeredQuestion)
        currentSessionAnswers.insert(currentQuestionIndex)
        lastAnswerCorrect = answeredQuestion.isCorrect
    }
    
    private func handleAutoAdvanceAfterAnswer() {
        Logger.quiz.debug("Auto-advance logic - canNavigateToNext: \(self.canNavigateToNext), isAtLast: \(self.isAtLastAvailableQuestion), isAnswered: \(self.isCurrentQuestionAnswered)")
        
        if canNavigateToNext {
            Logger.quiz.debug("Auto-advancing to next existing question")
            withAnimation {
                currentQuestionIndex += 1
                lastAnswerCorrect = nil
                isWaitingForNextQuestion = false
            }
        } else if isAtLastAvailableQuestion && isCurrentQuestionAnswered {
            Logger.quiz.debug("Setting waiting state - last question answered")
            isWaitingForNextQuestion = true
            lastKnownQuestionCount = currentQuestionCounts
            Logger.quiz.debug("Waiting state set - lastKnownQuestionCount set")
        }
    }
    
    func getPreviousAnswer(for question: MultipleChoiceQuestion) -> String? {
        return currentSessionAnsweredQuestions.first(where: { 
            $0.questionText == question.question && $0.questionType == .multipleChoice 
        })?.userAnswer
    }
    
    func getPreviousAnswer(for question: TrueFalseQuestion) -> Bool? {
        guard let userAnswer = currentSessionAnsweredQuestions.first(where: { 
            $0.questionText == question.question && $0.questionType == .trueFalse 
        })?.userAnswer else { return nil }
        
        return userAnswer == "True"
    }
}
