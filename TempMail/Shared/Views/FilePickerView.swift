//
//  FilePickerView.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView<Label: View>: View {
    let label: () -> Label
    let onFilePicked: (String) -> Void
    
    @State private var isPicking = false
    
    var body: some View {
        Button(action: {
            isPicking = true
        }) {
            label()
        }
        .fileImporter(
            isPresented: $isPicking,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                let content = try String(contentsOf: selectedFile)
                onFilePicked(content)
            } catch {
                print("Failed to read file: \(error.localizedDescription)")
            }
        }
    }
}


#Preview {
    FilePickerView(label: {
        Text("Select File")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }, onFilePicked: { content in
        print("File content:\n\(content)")
    })
}
