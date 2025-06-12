//
//  DocumentViewModel.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import SwiftUI

@Observable
final class DocumentViewModel {
    let item: Item
    let generator: Generator
    
    var isGenerating = false
    var currentQuestionIndex: Int = 0
    
    var currentPoints = 0
    
    init(item: Item) {
        self.item = item
        self.generator = Generator(item: item)
    }
    
    func answeredQuestion(question: Question, correct: Bool) {
        if currentQuestionIndex < item.questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }
}

