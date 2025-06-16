//
//  StringExtensions.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 16/06/2025.
//

import Foundation

extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            let endIdx = index(currentIndex, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[currentIndex..<endIdx]))
            currentIndex = endIdx
        }
        
        return chunks
    }
}
