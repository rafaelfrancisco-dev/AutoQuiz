//
//  AddContentView.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI
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

struct AddContentView: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var appStore
    
    @State private var isPickerPresented = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var newContent = ""
    @State private var contentSource: ContentSource = .file
    
    enum ContentSource: String, CaseIterable {
        case file = "File"
        case text = "Text"
        
        var systemImage: String {
            switch self {
            case .file: return "doc.fill"
            case .text: return "text.cursor"
            }
        }
    }
    
    var body: some View {
        Group {
            #if os(macOS)
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Add Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Add") {
                        addTextContent()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(contentSource == .text && newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        contentForm
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .macModalSize(.form)
            }
            #else
            NavigationView {
                Form {
                    contentForm
                }
                .navigationTitle("Add Content")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add") {
                            if contentSource == .file {
                                isPickerPresented = true
                            } else {
                                addTextContent()
                            }
                        }
                        .disabled(contentSource == .text && newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                DocumentPicker { url in
                    if let url = url {
                        handlePickedFile(url: url)
                    }
                }
            }
            #endif
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Success", isPresented: Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })) {
            Button("OK") { 
                successMessage = nil
                dismiss()
            }
        } message: {
            Text(successMessage ?? "")
        }
    }
    
    @ViewBuilder
    private var contentForm: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 20) {
            // Content Source Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Content Source")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Content Source", selection: $contentSource) {
                    ForEach(ContentSource.allCases, id: \.self) { source in
                        Label(source.rawValue, systemImage: source.systemImage).tag(source)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if contentSource == .file {
                // File Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Selection")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        selectFile()
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Choose File")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Text("Select a text file or PDF to append to this document.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Text Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Content")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $newContent)
                        .frame(minHeight: 200)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("Enter additional text content to append to this document.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        #else
        Section {
            Picker("Content Source", selection: $contentSource) {
                ForEach(ContentSource.allCases, id: \.self) { source in
                    Label(source.rawValue, systemImage: source.systemImage).tag(source)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Content Source")
        }
        
        if contentSource == .file {
            Section {
                Button(action: {
                    isPickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("Choose File")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("File Selection")
            } footer: {
                Text("Select a text file or PDF to append to this document.")
            }
        } else {
            Section {
                TextEditor(text: $newContent)
                    .frame(minHeight: 200)
            } header: {
                Text("Additional Content")
            } footer: {
                Text("Enter additional text content to append to this document.")
            }
        }
        #endif
    }
    
    #if os(macOS)
    private func selectFile() {
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
            var additionalContent = ""
            
            if fileType == UTType.pdf {
                #if canImport(PDFKit)
                if let pdfDoc = PDFDocument(url: url), let text = pdfDoc.string, !text.isEmpty {
                    additionalContent = text
                } else {
                    errorMessage = "Could not extract text from PDF."
                    return
                }
                #else
                errorMessage = "PDFKit not available to extract PDF text."
                return
                #endif
            } else {
                additionalContent = try String(contentsOf: url, encoding: .utf8)
            }
            
            appendContent(additionalContent)
            
        } catch {
            errorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }
    
    private func addTextContent() {
        let content = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        appendContent(content)
    }
    
    private func appendContent(_ content: String) {
        item.appendContentAndAdvanceRevision(content)
        Task {
            await appStore.saveItem(item)
            await MainActor.run {
                successMessage = "Content added successfully! Questions will be regenerated."
            }
        }
    }
}

#Preview {
    let sampleItem = Item(timestamp: .now, content: "Sample existing content")
    AddContentView(item: sampleItem)
        .environment(AppStore())
}
