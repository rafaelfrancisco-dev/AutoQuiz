//
//  DocumentViewModel.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class DocumentViewModel {
    let item: Item
    let generator: Generator
    var modelContext: ModelContext?
    
    var isGenerating = false
    var currentQuestionIndex: Int = 0
    
    var currentPoints: Int {
        return item.totalPoints
    }
    
    init(item: Item, modelContext: ModelContext? = nil) {
        self.item = item
        self.generator = Generator(item: item)
        self.modelContext = modelContext
    }
    
    func answeredQuestion(question: MultipleChoiceQuestion, correct: Bool, userAnswer: String) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestion(
            questionText: question.question,
            userAnswer: userAnswer,
            correctAnswer: question.anwswer,
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .multipleChoice
        )
        
        item.answeredQuestions.append(answeredQuestion)
        item.totalPoints += pointsEarned
        
        if let context = modelContext {
            context.insert(answeredQuestion)
            try? context.save()
        }
        
        if currentQuestionIndex < item.questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }
    
    func answeredTrueFalseQuestion(question: TrueFalseQuestion, correct: Bool, userAnswer: Bool) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestion(
            questionText: question.question,
            userAnswer: userAnswer ? "True" : "False",
            correctAnswer: question.isTrue ? "True" : "False",
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .trueFalse
        )
        
        item.answeredQuestions.append(answeredQuestion)
        item.totalPoints += pointsEarned
        
        if let context = modelContext {
            context.insert(answeredQuestion)
            try? context.save()
        }
        
        if currentQuestionIndex < (item.trueFalseQuestions?.count ?? 0) - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }
}
