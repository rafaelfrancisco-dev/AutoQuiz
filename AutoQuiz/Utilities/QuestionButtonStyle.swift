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

struct AnswerOptionButton: View {
    let title: String
    var subtitle: String? = nil
    let style: QuestionButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(style.hasAnswered ? style.textColor.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 12)

                if !style.icon.isEmpty {
                    Image(systemName: style.icon)
                        .font(.headline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(style.backgroundColor, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style.borderColor, lineWidth: 1)
            }
            .foregroundStyle(style.textColor)
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(style.scale)
        .animation(.easeOut(duration: 0.2), value: style.scale)
    }
}
