//
//  MainView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import FoundationModels

struct MainView: View {
    @State private var result: String? = nil
    
    private func doGenerate(_ session: LanguageModelSession) async throws {
        let prompt = "Write me a story about pears."
        let response = try await session.respond(to: prompt)
        
        withAnimation {
            result = response.content
        }
    }
    
    var body: some View {
        GenerativeView { session in
            VStack {
                Text("Hello, World!")
                
                if let result {
                    Text(result)
                }
            }
            .task {
                do {
                    try await doGenerate(session)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
