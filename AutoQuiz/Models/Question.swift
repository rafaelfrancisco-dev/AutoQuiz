//
//  Question.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftData
import FoundationModels

@Generable(description: "A multiple choice question with a valid response")
struct Question: Codable {
    @Guide(description: "The question text")
    let question: String
    
    @Guide(description: "All options for the multiple choice question, all must be distinct.")
    let options: [String]
    
    @Guide(description: "The correct answer for this question")
    let anwswer: String
}
