//
//  TrueFalseQuestionView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 15/06/2025.
//

import SwiftUI

struct TrueFalseQuestionView: View {
    let question: TrueFalseQuestion
    
    let onQuestionAnswered: (Bool, Bool) -> Void
    
    var body: some View {
        VStack {
            Text(question.question)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack(spacing: 40) {
                Button("True") {
                    onQuestionAnswered(question.isTrue, true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("False") {
                    onQuestionAnswered(!question.isTrue, false)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

#Preview {
    TrueFalseQuestionView(question: TrueFalseQuestion(question: "Swift is a programming language?", isTrue: true)) { _, _ in }
}