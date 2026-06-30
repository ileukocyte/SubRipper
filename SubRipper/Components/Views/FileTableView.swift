//
//  FileTableView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct FileTableView: View {
    @Bindable var file: SRTFile

    @Binding var showSubtitleInspector: Bool

    @State private var selection = Set<SRTEntry.ID>()
    @State private var searchQuery = ""
    @State private var searchSelectionIndex: Array.Index = 0
    @State private var showSubtitleOffsetSheet = false
    @State private var showLinearCorrectionSheet = false
    @State private var showSearchPanel = false

    private var selectedEntries: [Binding<SRTEntry>] {
        selection.compactMap { id in
            guard let index = file.entries.firstIndex(where: { $0.id == id }) else {
                return nil
            }

            return $file.entries[index]
        }
    }

    private var searchResults: [SRTEntry] {
        guard !searchQuery.isEmpty else {
            return []
        }

        return file.entries.filter { $0.content.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                if showSearchPanel {
                    HStack {
                        SearchBarView(query: $searchQuery) {
                            showSearchPanel.toggle()
                        } onUpArrow: {
                            selectPreviousSearchResult(scrollProxy: proxy)
                        } onDownArrow: {
                            selectNextSearchResult(scrollProxy: proxy)
                        }

                        HStack {
                            Stepper(searchResults.isEmpty ? "0 matches" : "\(searchSelectionIndex + 1)/\(searchResults.count)") {
                                selectPreviousSearchResult(scrollProxy: proxy)
                            } onDecrement: {
                                selectNextSearchResult(scrollProxy: proxy)
                            }
                            .disabled(searchResults.isEmpty)

                            Button("Done") {
                                showSearchPanel.toggle()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }

                Table(of: SRTEntry.self, selection: $selection) {
                    TableColumn("Start") {
                        Text(SRTMarshaler.formatTime($0.startTime))
                    }
                    .width(125)

                    TableColumn("End") {
                        Text(SRTMarshaler.formatTime($0.endTime))
                    }
                    .width(125)

                    TableColumn("Subtitle") {
                        Text(withSearchResultsHighlighted($0.content, options: .caseInsensitive))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2.5)
                    }
                } rows: {
                    ForEach(file.entries) { entry in
                        TableRow(entry)
                    }
                }
                .onChange(of: searchQuery) { _, newValue in
                    guard !newValue.isEmpty, let first = searchResults.first else {
                        return
                    }

                    selection = [first.id]
                    proxy.scrollTo(first.id, anchor: .center)
                }
                .onChange(of: showSearchPanel) { _, newValue in
                    guard newValue, !searchQuery.isEmpty, let first = searchResults.first else {
                        return
                    }

                    selection = [first.id]
                    proxy.scrollTo(first.id, anchor: .center)
                }
                .onChange(of: selection) { _, newValue in
                    guard newValue.count == 1,
                          let selected = newValue.first,
                          let index = searchResults.firstIndex(where: { $0.id == selected })
                    else {
                        return
                    }

                    searchSelectionIndex = index
                }
                .contextMenu(forSelectionType: SRTEntry.ID.self) { selected in
                    if selection != selected {
                        let _ = { selection = selected }()
                    }

                    let selectedEntriesMenu: [Binding<SRTEntry>] = selected.compactMap { id in
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
                                withAnimation {
                                    guard let newEntry = file.insertEntry(after: entry.wrappedValue) else {
                                        return
                                    }

                                    selection = [newEntry.id]
                                }
                            } label: {
                                Label("Insert Below", systemImage: "square.bottomthird.inset.filled")
                            }

                            Button {
                                withAnimation {
                                    guard let newEntry = file.insertEntry(before: entry.wrappedValue) else {
                                        return
                                    }

                                    selection = [newEntry.id]
                                }
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
                            withAnimation {
                                file.deleteAll(entries: selectedEntriesMenu.map(\.wrappedValue))
                            }

                            selection.removeAll()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .copyable(selectedEntries.map(\.wrappedValue.content))
            }
            .animation(.easeInOut, value: showSearchPanel)
        }
        .focusedSceneValue(\.entrySelection, $selection)
        .focusedSceneValue(\.showSubtitleOffsetSheet, $showSubtitleOffsetSheet)
        .focusedSceneValue(\.showLinearCorrectionSheet, $showLinearCorrectionSheet)
        .focusedSceneValue(\.showSearchPanel, $showSearchPanel)
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
            Section {
                SubtitleOffsetView(entries: selectedEntries, shouldDismiss: true)
            } header: {
                Text("Shift Time")
                    .font(.headline)
            }
            .padding()
            .frame(minWidth: 300, maxWidth: 300)
        }
        .sheet(isPresented: $showLinearCorrectionSheet) {
            Section {
                LinearCorrectionSheetView(file: file)
            } header: {
                Text("Linear Correction")
                    .font(.headline)
            }
            .padding()
            .frame(minWidth: 600, maxWidth: 600)
        }
    }

    private func selectPreviousSearchResult(scrollProxy proxy: ScrollViewProxy? = nil) {
        guard !searchResults.isEmpty else {
            return
        }

        var index = searchSelectionIndex

        if index > searchResults.startIndex {
            index -= 1
        } else {
            index = searchResults.endIndex - 1
        }

        let id = searchResults[index].id
        selection = [id]
        proxy?.scrollTo(id, anchor: .center)
    }

    private func selectNextSearchResult(scrollProxy proxy: ScrollViewProxy? = nil) {
        guard !searchResults.isEmpty else {
            return
        }

        var index = searchSelectionIndex

        if index < searchResults.endIndex - 1 {
            index += 1
        } else {
            index = searchResults.startIndex
        }

        let id = searchResults[index].id
        selection = [id]
        proxy?.scrollTo(id, anchor: .center)
    }

    private func withSearchResultsHighlighted(
        _ text: String,
        options: String.CompareOptions,
        backgroundColor color: Color = .yellow.opacity(0.3)
    ) -> AttributedString {
        var attributed = AttributedString(text)

        guard !searchQuery.isEmpty else {
            return attributed
        }

        var searchRange = attributed.startIndex..<attributed.endIndex

        while let range = attributed[searchRange].range(of: searchQuery, options: options) {
            attributed[range].backgroundColor = color
            searchRange = range.upperBound..<attributed.endIndex
        }

        return attributed
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
        file: SRTFile(
            url: url,
            entries: try! SRTMarshaler.unmarshal(from: content),
            originalContent: content
        ),
        showSubtitleInspector: .constant(true)
    )
    .navigationTitle("A Heart in Winter (1992).srt")
    .frame(width: 800, height: 500)
}
