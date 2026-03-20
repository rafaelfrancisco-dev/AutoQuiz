//
//  DocumentPicker.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

#if os(iOS) || os(visionOS)
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    var completion: (URL?) -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.plainText, UTType.text, UTType.content, UTType.pdf], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL?) -> Void
        
        init(completion: @escaping (URL?) -> Void) { self.completion = completion }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
}
#endif
