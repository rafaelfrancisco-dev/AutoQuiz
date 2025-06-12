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
    
    init(item: Item) {
        self.item = item
        self.generator = Generator(item: item)
    }
}
