//
//  SubtitleTextEditorView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/18/2026.
//

import SwiftUI

struct SubtitleTextEditorView: View {
    @Binding var content: String

    @State private var draft: String

    init(content: Binding<String>) {
        self._content = content
        self._draft = State(initialValue: content.wrappedValue)
    }

    var canSave: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        return !trimmed.isEmpty && content != trimmed
    }

    var body: some View {
        Group {
            TextEditor(text: $draft)
                .font(.system(.body))
                .scrollContentBackground(.hidden)
                .frame(height: 100)
                .onChange(of: draft) { _, newValue in
                    draft = newValue.replacing(/\n{2,}/, with: "\n")
                }

            HStack {
                Spacer()

                Button("Save") {
                    draft = draft
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        .joined(separator: "\n")
                    content = draft
                }
                .disabled(!canSave)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)

                Spacer()
            }
        }
    }
}

#Preview {
    @Previewable @State var content = "Why are you\nall dressed up?"

    Form {
        Section(header: Text("Subtitle")) {
            SubtitleTextEditorView(content: $content)
        }
    }
    .formStyle(.grouped)
    .frame(width: 300)
}
