//
//  Question.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import FoundationModels

@Generable(description: "A multiple choice question with a valid response")
struct MultipleChoiceQuestion: Codable {
    @Guide(description: "The question text")
    let question: String

    @Guide(description: "All options for the multiple choice question, all must be distinct and the count must always be four. Don't add the A., B., C. and so on prefix")
    let options: [String]

    @Guide(description: "The correct answer for this question")
    let anwswer: String
}
