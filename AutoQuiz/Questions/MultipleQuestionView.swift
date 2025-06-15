//
//  QuestionView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 11/06/2025.
//

import SwiftUI

struct MultipleQuestionView: View {
    let question: MultipleChoiceQuestion
    
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
    MultipleQuestionView(question: MultipleChoiceQuestion(question: "Yes ?", options: ["Yes", "No"], anwswer: "Yes")) { _ in }
}
