//
//  Question.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import FoundationModels

@Generable(description: "A multiple choice question")
struct Question {
    @Guide(description: "The question text")
    let question: String
    
    @Guide(description: "All options for the multiple choice question")
    let options: [String]
    
    @Guide(description: "The correct answer")
    let anwswer: String
}
