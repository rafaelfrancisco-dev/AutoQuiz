//
//  ContentView.swift
//  AutoQuiz
//

import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var isPickerPresented = false
    @State private var errorMessage: String?
    @State private var selectedItemID: Item.ID?
    @State private var appAvailabilityIssue: GeneratorError?

    private var items: [Item] {
        appStore.items
    }

    var body: some View {
        Group {
            if appStore.isBootstrapping {
                ProgressView("Loading documents...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let appAvailabilityIssue {
                unavailableView(for: appAvailabilityIssue)
            } else {
                splitView
            }
        }
        .task {
            refreshAppAvailability()
            await appStore.refreshItems()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshAppAvailability()
                Task {
                    await appStore.refreshItems()
                }
            }
        }
        .onChange(of: appStore.lastErrorMessage) { _, newValue in
            if let newValue {
                errorMessage = newValue
            }
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        #if os(iOS) || os(visionOS)
        .sheet(isPresented: $isPickerPresented) {
            DocumentPicker { url in
                if let url {
                    handlePickedFile(url: url)
                }
            }
        }
        #endif
    }

    private var splitView: some View {
        NavigationSplitView {
            List(selection: $selectedItemID) {
                ForEach(items) { item in
                    DocumentListRow(item: item)
                        .tag(item.id)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("document-row-\(item.id.uuidString)")
                }
                .onDelete(perform: deleteItems)
            }
            .accessibilityIdentifier("document-list")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            #endif
            .navigationTitle("Documents")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
                #endif

                ToolbarItem(placement: .primaryAction) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("add-item")
                }
            }
        } detail: {
            if let selectedItem {
                DocumentView(item: selectedItem)
            } else {
                AppEmptyState(
                    title: "Select a Document",
                    systemImage: "doc.text",
                    description: "Choose a document from the sidebar to start a quiz, review analytics, or add more content."
                )
                .accessibilityIdentifier("document-empty-state")
            }
        }
        .accessibilityIdentifier("root-split-view")
    }

    private var selectedItem: Item? {
        guard let selectedItemID else { return nil }
        return items.first(where: { $0.id == selectedItemID })
    }

    @ViewBuilder
    private func unavailableView(for issue: GeneratorError) -> some View {
        VStack(spacing: 16) {
            Text("Apple Intelligence Required")
                .font(.title2.weight(.semibold))
            Text(issue.userFacingMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                refreshAppAvailability()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .appContentWidth(560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func refreshAppAvailability() {
        appAvailabilityIssue = Generator.currentAvailabilityIssue()
    }

    #if os(iOS) || os(visionOS)
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
            let content = try FileHandler.extractContent(from: url)
            Task {
                await appStore.addItem(content: content)
            }
        } catch let error as FileHandler.FileError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = items[index]

                Task {
                    await appStore.deleteItem(item)
                }

                if selectedItemID == item.id {
                    selectedItemID = nil
                }
            }
        }
    }
}

private struct DocumentListRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title ?? "Untitled Document")
                .font(.headline)
                .lineLimit(1)
                .accessibilityIdentifier("document-title-\(item.id.uuidString)")

            Text(item.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                AppBadge(text: "\(item.questions.count + (item.trueFalseQuestions?.count ?? 0)) questions", tone: .info)
                AppBadge(text: "v\(item.contentRevision)", tone: .neutral)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let previewStore = AppStore.preview(items: [PreviewData.sampleItem()])
    ContentView()
        .environment(previewStore)
}
