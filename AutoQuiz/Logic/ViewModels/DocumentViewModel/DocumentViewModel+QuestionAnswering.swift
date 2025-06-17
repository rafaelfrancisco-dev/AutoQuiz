//
//  DocumentViewModel+QuestionAnswering.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI

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
        print("DEBUG: Auto-advance logic - canNavigateToNext: \(canNavigateToNext), isAtLast: \(isAtLastAvailableQuestion), isAnswered: \(isCurrentQuestionAnswered)")
        
        if canNavigateToNext {
            print("DEBUG: Auto-advancing to next existing question")
            withAnimation {
                currentQuestionIndex += 1
                lastAnswerCorrect = nil
                isWaitingForNextQuestion = false
            }
        } else if isAtLastAvailableQuestion && isCurrentQuestionAnswered {
            print("DEBUG: Setting waiting state - last question answered")
            isWaitingForNextQuestion = true
            lastKnownQuestionCount = currentQuestionCounts
            print("DEBUG: Waiting state set - lastKnownQuestionCount: \(lastKnownQuestionCount)")
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
