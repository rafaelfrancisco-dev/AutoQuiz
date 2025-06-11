//
//  GenerativeView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import FoundationModels

struct GenerativeView<Content: View>: View {
    let content: (LanguageModelSession) -> Content
    
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default
    
    init(@ViewBuilder content: @escaping (LanguageModelSession) -> Content) {
        self.content = content
    }
    
    var body: some View {
        switch model.availability {
        case .available:
            content(LanguageModelSession(instructions: "Always answer in English."))
        case .unavailable(let reason):
            unavailable(reason: String(describing: reason))
        }
    }
    
    private func unavailable(reason: String) -> some View {
        Text(reason)
    }
}
