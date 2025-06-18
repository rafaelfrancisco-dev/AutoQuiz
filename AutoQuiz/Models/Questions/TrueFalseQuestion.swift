//
//  TrueFalseQuestion.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 15/06/2025.
//

import FoundationModels

@Generable(description: "A true or false question")
struct TrueFalseQuestion: Codable {
    @Guide(description: "The question text")
    let question: String
    
    @Guide(description: "If the question is true or false (50% chance of either)")
    let isTrue: Bool
}
