//
//  FileHandler.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import Foundation
import UniformTypeIdentifiers
#if canImport(PDFKit)
import PDFKit
#endif

struct FileHandler {
    enum FileError: LocalizedError {
        case pdfExtractionFailed
        case pdfKitUnavailable
        case fileReadFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .pdfExtractionFailed:
                return "Could not extract text from PDF."
            case .pdfKitUnavailable:
                return "PDFKit not available to extract PDF text."
            case .fileReadFailed(let error):
                return "Could not read file: \(error.localizedDescription)"
            }
        }
    }
    
    static let supportedContentTypes: [UTType] = [
        UTType.plainText,
        UTType.text,
        UTType.content,
        UTType.pdf
    ]
    
    static func extractContent(from url: URL) throws -> String {
        let fileType = UTType(filenameExtension: url.pathExtension)
        
        if fileType == UTType.pdf {
            return try extractPDFContent(from: url)
        } else {
            return try extractTextContent(from: url)
        }
    }
    
    private static func extractPDFContent(from url: URL) throws -> String {
        #if canImport(PDFKit)
        guard let pdfDoc = PDFDocument(url: url),
              let text = pdfDoc.string,
              !text.isEmpty else {
            throw FileError.pdfExtractionFailed
        }
        return text
        #else
        throw FileError.pdfKitUnavailable
        #endif
    }
    
    private static func extractTextContent(from url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw FileError.fileReadFailed(error)
        }
    }
}