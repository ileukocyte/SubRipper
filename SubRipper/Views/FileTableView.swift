//
//  FileTableView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct FileTableView: View {
    @Binding var entries: [SrtEntry]
    @Binding var isEditing: Bool

    @State private var selection: SrtEntry.ID?

    private var selectedEntry: Binding<SrtEntry>? {
        guard let selection else { return nil }
        guard let index = entries.firstIndex(where: { $0.id == selection }) else { return nil }

        return $entries[index]
    }

    var body: some View {
        Table(of: SrtEntry.self, selection: $selection) {
            TableColumn("Start") {
                Text(SrtMarshaler.formatTime($0.startTime))
            }
            .width(125)

            TableColumn("End") {
                Text(SrtMarshaler.formatTime($0.endTime))
            }
            .width(125)

            TableColumn("Subtitle") {
                Text($0.content)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2.5)
            }
        } rows: {
            ForEach(entries) { entry in
                TableRow(entry)
                    .contextMenu {
                        Button(role: .destructive) {
                            
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .inspector(isPresented: $isEditing) {
            if let selectedEntry {
                SubtitleInspectorView(selectedEntry: selectedEntry)
                    .inspectorColumnWidth(min: 250, ideal: 300, max: 500)
            } else {
                ContentUnavailableView {
                    Image(systemName: "pencil.and.ellipsis.rectangle")
                } description: {
                    Text("Select a subtitle to edit")
                }
                .inspectorColumnWidth(min: 250, ideal: 300, max: 500)
            }
        }
    }
}

#Preview {
    @Previewable @State var entries = try! SrtMarshaler.unmarshal("""
1
00:00:28,571 --> 00:00:31,658
(door opens)

2
00:00:31,825 --> 00:00:33,785
(door closes)

3
00:00:33,952 --> 00:00:36,788
(approaching footsteps)

4
00:00:41,876 --> 00:00:43,545
Mom?

5
00:00:46,089 --> 00:00:48,466
- Kat?

6
00:00:49,467 --> 00:00:52,846
Yeah. I'm fine.

7
00:00:54,264 --> 00:00:56,266
Why are you
all dressed up?

8
00:00:56,433 --> 00:00:58,351
What do you mean?
""")

    FileTableView(entries: $entries, isEditing: .constant(true))
        .navigationTitle("A Heart in Winter (1992).srt")
        .frame(width: 800, height: 500)
}
