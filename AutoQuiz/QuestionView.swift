//
//  QuestionView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 11/06/2025.
//

import SwiftUI

struct QuestionView: View {
    let question: Question
    
    let onQuestionAnswered: (Bool) -> Void
    
    var body: some View {
        VStack {
            Text(question.question)
            
            ForEach(question.options, id: \.self) { q in
                Button(q) {
                    onQuestionAnswered(q == question.anwswer)
                }
            }
        }
    }
}

#Preview {
    QuestionView(question: Question(question: "Yes ?", options: ["Yes", "No"], anwswer: "Yes")) { _ in }
}
