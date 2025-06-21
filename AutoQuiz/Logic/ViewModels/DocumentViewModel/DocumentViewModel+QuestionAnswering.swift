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
        
        // Auto-advance after brief delay for UI feedback
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await handleAutoAdvanceAfterAnswer()
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
        
        // Auto-advance after brief delay for UI feedback
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await handleAutoAdvanceAfterAnswer()
        }
    }
    
    private func recordAnswer(_ answeredQuestion: AnsweredQuestionV1) {
        currentSessionAnsweredQuestions.append(answeredQuestion)
        currentSessionAnswers.insert(currentQuestionIndex)
        lastAnswerCorrect = answeredQuestion.isCorrect
    }
    
    @MainActor
    private func handleAutoAdvanceAfterAnswer() async {
        Logger.quiz.debug("Handling auto-advance after answer")
        
        // Case 3: Check if we've reached the maximum questions (quiz should end)
        if !self.currentQuizSettings.isUnlimitedQuestions && 
           self.currentSessionAnsweredQuestions.count >= self.currentQuizSettings.maxQuestions {
            Logger.quiz.debug("Reached maximum questions (\(self.currentQuizSettings.maxQuestions)) - ending quiz")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Brief delay for UI feedback
            self.endQuiz()
            return
        }
        
        // Case 1: Question is already prepared - navigate immediately
        if canNavigateToNext {
            Logger.quiz.debug("Next question ready - navigating immediately")
            navigateToNextQuestion()
            return
        }
        
        // Case 2: Need to wait for generator - set waiting state and let generator notify us
        Logger.quiz.debug("No next question available - waiting for background generation")
        isWaitingForNextQuestion = true
        
        // Ensure background generation is running (it will notify us when ready)
        if !isBackgroundGenerating {
            startBackgroundGeneration()
        }
    }
    
    @MainActor
    func navigateToNextQuestion() {
        guard canNavigateToNext else {
            Logger.quiz.warning("Attempted to navigate but no next question available")
            return
        }
        
        withAnimation {
            currentQuestionIndex += 1
            lastAnswerCorrect = nil
            isWaitingForNextQuestion = false
        }
        
        Logger.quiz.debug("Successfully navigated to question \(self.currentQuestionIndex)")
        
        // Check if we landed on a pre-answered question and continue auto-advancing
        skipPreAnsweredQuestions()
    }
    
    @MainActor
    private func skipPreAnsweredQuestions() {
        // Keep advancing through pre-answered questions until we find an unanswered one
        // or reach the end/limit
        while isCurrentQuestionAnswered && canNavigateToNext {
            Logger.quiz.debug("Skipping pre-answered question at index \(self.currentQuestionIndex)")
            
            // Check if we've reached the maximum questions for non-unlimited quizzes
            if !currentQuizSettings.isUnlimitedQuestions && 
               currentSessionAnsweredQuestions.count >= currentQuizSettings.maxQuestions {
                Logger.quiz.debug("Reached maximum questions while skipping - ending quiz")
                endQuiz()
                return
            }
            
            withAnimation {
                currentQuestionIndex += 1
            }
        }
        
        // After skipping, check if we need to wait for more questions or end the quiz
        if !canNavigateToNext {
            // Check if we've reached the question limit
            if !currentQuizSettings.isUnlimitedQuestions && 
               currentSessionAnsweredQuestions.count >= currentQuizSettings.maxQuestions {
                Logger.quiz.debug("Reached maximum questions after skipping - ending quiz")
                endQuiz()
            } else {
                // Need more questions - set waiting state
                Logger.quiz.debug("Reached end of available questions after skipping - waiting for generation")
                isWaitingForNextQuestion = true
                if !isBackgroundGenerating {
                    startBackgroundGeneration()
                }
            }
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
