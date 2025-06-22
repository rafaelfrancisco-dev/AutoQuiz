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
        case fileTooLarge(fileSize: Int64, maxSize: Int64)
        
        var errorDescription: String? {
            switch self {
            case .pdfExtractionFailed:
                return "Could not extract text from PDF."
            case .pdfKitUnavailable:
                return "PDFKit not available to extract PDF text."
            case .fileReadFailed(let error):
                return "Could not read file: \(error.localizedDescription)"
            case .fileTooLarge(let fileSize, let maxSize):
                let fileSizeMB = Double(fileSize) / (1024 * 1024)
                let maxSizeMB = Double(maxSize) / (1024 * 1024)
                return String(format: "File is too large (%.1f MB). Maximum allowed size is %.0f MB.", fileSizeMB, maxSizeMB)
            }
        }
    }
    
    static let supportedContentTypes: [UTType] = [
        UTType.plainText,
        UTType.text,
        UTType.content,
        UTType.pdf
    ]
    
    static let maxTextFileSize: Int64 = 10 * 1024 * 1024  // 10 MB
    static let maxPDFFileSize: Int64 = 50 * 1024 * 1024   // 50 MB
    
    static func extractContent(from url: URL) throws -> String {
        try validateFileSize(url: url)
        
        let fileType = UTType(filenameExtension: url.pathExtension)
        
        if fileType == UTType.pdf {
            return try extractPDFContent(from: url)
        } else {
            return try extractTextContent(from: url)
        }
    }
    
    private static func validateFileSize(url: URL) throws {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = fileAttributes[.size] as? Int64 else {
            throw FileError.fileReadFailed(NSError(domain: "FileHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine file size"]))
        }
        
        let fileType = UTType(filenameExtension: url.pathExtension)
        let maxSize: Int64
        
        if fileType == UTType.pdf {
            maxSize = maxPDFFileSize
        } else {
            maxSize = maxTextFileSize
        }
        
        if fileSize > maxSize {
            throw FileError.fileTooLarge(fileSize: fileSize, maxSize: maxSize)
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