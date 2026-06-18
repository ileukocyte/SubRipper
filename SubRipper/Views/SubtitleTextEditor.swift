//
//  SubtitleTextEditor.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/18/2026.
//

import SwiftUI

struct SubtitleTextEditor: View {
    @Binding var content: String

    @State private var draft: String

    init(content: Binding<String>) {
        self._content = content
        self._draft = State(initialValue: content.wrappedValue)
    }

    var canSave: Bool {
        content != draft
    }

    var body: some View {
        Group {
            TextEditor(text: $draft)
                .font(.system(.body))
                .scrollContentBackground(.hidden)
                .frame(height: 100)

            HStack {
                Spacer()

                Button("Save") {
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
            SubtitleTextEditor(content: $content)
        }
    }
    .formStyle(.grouped)
    .frame(width: 300)
}
