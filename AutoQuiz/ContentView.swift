//
//  ContentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(PDFKit)
import PDFKit
#endif
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var isPickerPresented = false
    @State private var pickedFileURL: URL?
    @State private var errorMessage: String?
    @State private var selectedItemID: Item.ID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItemID) {
                ForEach(items) { item in
                    NavigationLink(value: item.id) {
                        if let title = item.title {
                            Text(title)
                        } else {
                            Text(item.content.prefix(40))
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .navigationTitle("Documents")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem(placement: .navigation) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
#if os(iOS)
            .sheet(isPresented: $isPickerPresented) {
#if os(iOS)
                DocumentPicker { url in
                    if let url = url {
                        handlePickedFile(url: url)
                    }
                }
#endif
            }
#endif
            .alert(isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? ""),
                    dismissButton: .default(Text("OK")) { errorMessage = nil }
                )
            }
        } detail: {
            if let selID = selectedItemID,
               let selectedItem = items.first(where: { $0.id == selID })
            {
                DocumentView(item: selectedItem)
            } else {
                Text("Select an item")
            }
        }
    }

#if os(iOS)
    private func addItem() {
        isPickerPresented = true
    }
#elseif os(macOS)
    private func addItem() {
        let panel = NSOpenPanel()
        
        panel.allowedContentTypes = [UTType.plainText, UTType.text, UTType.content, UTType.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                handlePickedFile(url: url)
            }
        }
    }
#endif

    private func handlePickedFile(url: URL) {
        do {
            let fileType = UTType(filenameExtension: url.pathExtension)
            if fileType == UTType.pdf {
#if canImport(PDFKit)
                if let pdfDoc = PDFDocument(url: url), let text = pdfDoc.string, !text.isEmpty {
                    let newItem = Item(timestamp: Date(), content: text)
                    modelContext.insert(newItem)
                } else {
                    errorMessage = "Could not extract text from PDF."
                }
#else
                errorMessage = "PDFKit not available to extract PDF text."
#endif
            } else {
                let content = try String(contentsOf: url, encoding: .utf8)
                let newItem = Item(timestamp: Date(), content: content)
                modelContext.insert(newItem)
            }
        } catch {
            errorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = items[index]
                modelContext.delete(item)
                
                if selectedItemID == item.id {
                    selectedItemID = nil
                }
            }
        }
    }
}

#if os(iOS)
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
