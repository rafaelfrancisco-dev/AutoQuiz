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
    @Environment(\.scenePhase) private var scenePhase
    @Query private var items: [Item]

    @State private var isPickerPresented = false
    @State private var pickedFileURL: URL?
    @State private var errorMessage: String?
    @State private var selectedItemID: Item.ID?
    @State private var appAvailabilityIssue: GeneratorError?

    var body: some View {
        Group {
            if let appAvailabilityIssue {
                unavailableView(for: appAvailabilityIssue)
            } else {
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
        }
        .task {
            refreshAppAvailability()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshAppAvailability()
            }
        }
    }
    
    @ViewBuilder
    private func unavailableView(for issue: GeneratorError) -> some View {
        VStack(spacing: 16) {
            Text("Apple Intelligence Required")
                .font(.title2)
                .bold()
            Text(issue.userFacingMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                refreshAppAvailability()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
    
    private func refreshAppAvailability() {
        appAvailabilityIssue = Generator.currentAvailabilityIssue()
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
            let content = try FileHandler.extractContent(from: url)
            let newItem = Item(timestamp: Date(), content: content)
            modelContext.insert(newItem)
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
                modelContext.delete(item)
                
                if selectedItemID == item.id {
                    selectedItemID = nil
                }
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
