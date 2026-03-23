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
#if os(macOS)
import AppKit
#endif

struct AddContentView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var appStore

    @State private var isPickerPresented = false
    @State private var errorMessage: String?
    @State private var newContent = ""
    @State private var contentSource: ContentSource = .file

    enum ContentSource: String, CaseIterable {
        case file = "File"
        case text = "Text"

        var systemImage: String {
            switch self {
            case .file:
                return "doc"
            case .text:
                return "text.alignleft"
            }
        }
    }

    var body: some View {
        #if os(macOS)
        macBody
        #else
        mobileBody
        #endif
    }

    #if os(macOS)
    private var macBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppMacModalHeader(
                    title: "Add Content",
                    subtitle: "Append new material to this document and regenerate its questions."
                ) {
                    Button("Close") {
                        dismiss()
                    }
                }

                AppMacFormSection(title: "Content Source") {
                    Picker("Content Source", selection: $contentSource) {
                        ForEach(ContentSource.allCases, id: \.self) { source in
                            Text(source.rawValue)
                                .tag(source)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }

                if contentSource == .file {
                    AppMacFormSection(
                        title: "Import File",
                        footer: "Select a text file or PDF to append to this document."
                    ) {
                        Button(action: triggerFileImport) {
                            Label("Choose File", systemImage: "doc.badge.plus")
                        }
                    }
                } else {
                    AppMacFormSection(
                        title: "Additional Content",
                        footer: "Enter additional text content to append to this document."
                    ) {
                        TextEditor(text: $newContent)
                            .font(.body)
                            .frame(minHeight: 220)
                            .padding(10)
                            .background(Color.platformControlBackground, in: .rect(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.platformBorder.opacity(0.55), lineWidth: 1)
                            }
                    }
                }

                HStack {
                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }

                    Button("Add") {
                        submitContent()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(contentSource == .text && trimmedContent.isEmpty)
                }
            }
            .padding(24)
            .frame(maxWidth: 620, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityIdentifier("add-content-screen")
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .macModalSize(.utilityForm)
        .alert("Error", isPresented: errorBinding) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    #endif

    private var mobileBody: some View {
        NavigationStack {
            Form {
                Section("Content Source") {
                    Picker("Content Source", selection: $contentSource) {
                        ForEach(ContentSource.allCases, id: \.self) { source in
                            Label(source.rawValue, systemImage: source.systemImage)
                                .tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if contentSource == .file {
                    Section {
                        Button(action: triggerFileImport) {
                            Label("Choose File", systemImage: "doc.badge.plus")
                        }
                        .accessibilityIdentifier("choose-additional-content-file")

                        Text("Select a text file or PDF to append to this document.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Import File")
                    }
                } else {
                    Section {
                        TextEditor(text: $newContent)
                            .frame(minHeight: 220)
                            .padding(.vertical, 4)
                    } header: {
                        Text("Additional Content")
                    } footer: {
                        Text("Enter additional text content to append to this document.")
                    }
                }
            }
            .accessibilityIdentifier("add-content-screen")
            .navigationTitle("Add Content")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        submitContent()
                    }
                    .disabled(contentSource == .text && trimmedContent.isEmpty)
                }
            }
        }
        .macModalSize(.utilityForm)
        #if os(iOS)
        .sheet(isPresented: $isPickerPresented) {
            DocumentPicker { url in
                if let url {
                    handlePickedFile(url: url)
                }
            }
        }
        #endif
        .alert("Error", isPresented: errorBinding) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var trimmedContent: String {
        newContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func triggerFileImport() {
        #if os(macOS)
        selectFile()
        #else
        isPickerPresented = true
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
            let additionalContent: String

            if fileType == .pdf {
                #if canImport(PDFKit)
                guard let pdfDoc = PDFDocument(url: url), let text = pdfDoc.string, !text.isEmpty else {
                    errorMessage = "Could not extract text from PDF."
                    return
                }
                additionalContent = text
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
        guard !trimmedContent.isEmpty else { return }
        appendContent(trimmedContent)
    }

    private func submitContent() {
        if contentSource == .file {
            triggerFileImport()
        } else {
            addTextContent()
        }
    }

    private func appendContent(_ content: String) {
        item.appendContentAndAdvanceRevision(content)
        Task {
            await appStore.saveItem(item)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview("Text Content") {
    let sampleItem = PreviewData.sampleItem()
    return AddContentView(item: sampleItem)
        .environment(AppStore())
}
