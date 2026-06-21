//
//  FileTableView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct FileTableView: View {
    @Bindable var file: SrtFile

    @Binding var showSubtitleInspector: Bool

    @State private var selection = Set<SrtEntry.ID>()
    @State private var showSubtitleOffsetSheet = false

    private var selectedEntries: [Binding<SrtEntry>] {
        selection.compactMap { id in
            guard let index = file.entries.firstIndex(where: { $0.id == id }) else {
                return nil
            }

            return $file.entries[index]
        }
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
            ForEach(file.entries) { entry in
                TableRow(entry)
            }
        }
        .focusedSceneValue(\.selectedEntries, $selection)
        .focusedSceneValue(\.showSubtitleOffsetSheet, $showSubtitleOffsetSheet)
        .contextMenu(forSelectionType: SrtEntry.ID.self) { selected in
            let _ = {
                if selection != selected {
                    selection = selected
                }
            }()

            let selectedEntriesMenu: [Binding<SrtEntry>] = selected.compactMap { id in
                guard let index = file.entries.firstIndex(where: { entry in
                    entry.id == id
                }) else {
                    return nil
                }

                return $file.entries[index]
            }

            if !selectedEntriesMenu.isEmpty {
                if selectedEntriesMenu.count == 1, let entry = selectedEntriesMenu.first {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.wrappedValue.content, forType: .string)
                    } label: {
                        Label("Copy Subtitle", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button {
                        file.insertEntry(after: entry.wrappedValue)
                    } label: {
                        Label("Insert Below", systemImage: "square.bottomthird.inset.filled")
                    }

                    Button {
                        file.insertEntry(before: entry.wrappedValue)
                    } label: {
                        Label("Insert Above", systemImage: "square.topthird.inset.filled")
                    }
            
                    Divider()
                }

                Button {
                    showSubtitleOffsetSheet.toggle()
                } label: {
                    Label("Shift Time", systemImage: "timer")
                }

                Divider()

                Button(role: .destructive) {
                    file.deleteAll(entries: selectedEntriesMenu.map(\.wrappedValue))
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .inspector(isPresented: $showSubtitleInspector) {
            if !selectedEntries.isEmpty {
                SubtitleInspectorView(entries: selectedEntries) {
                    selection = Set(file.entries.map(\.id))
                } deselect: {
                    selection.removeAll()
                }
                .inspectorColumnWidth(min: 250, ideal: 300, max: 350)
            } else {
                ContentUnavailableView {
                    Image(systemName: "filemenu.and.selection")
                } description: {
                    Text("Select a subtitle to edit")
                }
                .inspectorColumnWidth(min: 250, ideal: 300, max: 350)
            }
        }
        .sheet(isPresented: $showSubtitleOffsetSheet) {
            Section(header: Text("Shift Time")) {
                SubtitleOffsetView(entries: selectedEntries, shouldDismiss: true)
            }
            .padding()
        }
    }
}

#Preview {
    let url = URL(fileURLWithPath: "A Heart in Winter (1992).srt")
    let content = """
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
"""

    FileTableView(
        file: SrtFile(
            url: url,
            entries: try! SrtMarshaler.unmarshal(from: content),
            originalContent: content
        ),
        showSubtitleInspector: .constant(true)
    )
    .navigationTitle("A Heart in Winter (1992).srt")
    .frame(width: 800, height: 500)
}
