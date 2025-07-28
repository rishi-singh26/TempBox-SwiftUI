//
//  NewFolderView.swift
//  TempBox
//
//  Created by Rishi Singh on 28/07/25.
//

import SwiftUI

struct NewFolderView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var folderName: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var folder: Folder?
    
    init(folder: Folder? = nil) {
        self.folder = folder
        _folderName = State(wrappedValue: folder?.name ?? "")
    }

    var body: some View {
        Group {
#if os(iOS)
            IOSNewFolder()
#elseif os(macOS)
            MacOSNewFolder()
#endif
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSNewFolder() -> some View {
        NavigationView {
            Form {
                Section {
                    TextField("Folder name", text: $folderName)
                        .textInputAutocapitalization(.words)
                        .focused($isTextFieldFocused)
                        .onSubmit(createFolder)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        createFolder()
                    } label: {
                        Text("Create")
                            .font(.headline)
                    }
                    .disabled(folderName.isEmpty)

                }
            }
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSNewFolder() -> some View {
        VStack {
            HStack {
                Text("New Folder")
                    .font(.title.bold())
                Spacer()
            }
            .padding()
            ScrollView {
                Form {
                    MacCustomSection(footer: "") {
                        TextField("New Folder Name", text: $folderName)
                            .textFieldStyle(.roundedBorder)
                            .focused($isTextFieldFocused)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            createFolder()
                        } label: {
                            Text("Create")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
#endif
    
    private func createFolder() {
        do {
            guard !folderName.isEmpty else { return }
            let newFolder = Folder(id: UUID().uuidString, name: folderName)
            modelContext.insert(newFolder)
            try modelContext.save()
            dismiss()
        } catch {
            print(error.localizedDescription)
        }
    }
}
