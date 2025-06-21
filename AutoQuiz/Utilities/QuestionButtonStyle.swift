//
//  QuestionButtonStyle.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI

struct QuestionButtonStyle {
    let hasAnswered: Bool
    let isCorrect: Bool
    let isSelected: Bool
    
    var textColor: Color {
        guard hasAnswered else { return .primary }
        
        if isCorrect {
            return .white
        } else if isSelected {
            return .white
        } else {
            return .secondary
        }
    }
    
    var backgroundColor: Color {
        guard hasAnswered else { 
            return .platformControlBackground
        }
        
        if isCorrect {
            return .green
        } else if isSelected {
            return .red
        } else {
            return .platformSecondaryBackground
        }
    }
    
    var borderColor: Color {
        guard hasAnswered else { 
            return .platformBorder
        }
        
        if isCorrect {
            return .green
        } else if isSelected {
            return .red
        } else {
            return .platformBorder
        }
    }
    
    var icon: String {
        if isCorrect {
            return "checkmark.circle.fill"
        } else if isSelected {
            return "xmark.circle.fill"
        } else {
            return ""
        }
    }
    
    var scale: CGFloat {
        guard hasAnswered else { return 1.0 }
        
        if isCorrect || isSelected {
            return 1.02
        } else {
            return 0.98
        }
    }
    
    static func forMultipleChoice(
        option: String,
        correctAnswer: String,
        selectedAnswer: String?,
        hasAnswered: Bool
    ) -> QuestionButtonStyle {
        let isCorrect = option == correctAnswer
        let isSelected = option == selectedAnswer
        
        return QuestionButtonStyle(
            hasAnswered: hasAnswered,
            isCorrect: isCorrect,
            isSelected: isSelected
        )
    }
    
    static func forTrueFalse(
        answer: Bool,
        correctAnswer: Bool,
        selectedAnswer: Bool?,
        hasAnswered: Bool
    ) -> QuestionButtonStyle {
        let isCorrect = answer == correctAnswer
        let isSelected = answer == selectedAnswer
        
        return QuestionButtonStyle(
            hasAnswered: hasAnswered,
            isCorrect: isCorrect,
            isSelected: isSelected
        )
    }
}