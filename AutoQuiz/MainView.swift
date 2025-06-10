import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct TextEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var text: String = ""
    
    var body: some View {
        VStack {
            TextEditor(text: $text)
                .padding()
            Button("Save as PDF") {
                saveAsPDF()
            }
        }
    }
    
    func saveAsPDF() {
        let pdfData = Data() // Implementation for PDF data generation
        let newFile = FileEntity(data: pdfData, typeIdentifier: UTType.pdf.identifier)
        modelContext.insert(newFile)
    }
}

@Model
final class FileEntity {
    @Attribute(.externalStorage)
    var data: Data
    var typeIdentifier: String

    init(data: Data, typeIdentifier: String) {
        self.data = data
        self.typeIdentifier = typeIdentifier
    }
}
