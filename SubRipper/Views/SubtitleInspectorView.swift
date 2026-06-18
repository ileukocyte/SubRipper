//
//  SubtitleInspectorView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct SubtitleInspectorView: View {
    @Binding var selectedEntry: SrtEntry

    var body: some View {
        Form {
            Section(header: Text("Subtitle")) {
                TextEditor(text: $selectedEntry.content)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
            }

            Section(header: Text("Timing")) {
                LabeledContent("Start", value: SrtMarshaler.formatTime(selectedEntry.startTime))
                LabeledContent("End", value: SrtMarshaler.formatTime(selectedEntry.endTime))
            }
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var entry = SrtEntry(id: 1, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?")
    ZStack {}
        .inspector(isPresented: .constant(true)) {
            SubtitleInspectorView(selectedEntry: $entry)
        }
}
