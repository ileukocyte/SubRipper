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
    @State private var showSubtitleOffsetSheet = false
    @State private var showLinearCorrectionSheet = false

    @State private var showSearchPanel = false
    @State private var searchQuery = ""
    @State private var debouncedSearchQuery = ""
    @State private var searchSelectionIndex: Array<SRTEntry>.Index = -1
    @State private var matchCase = false

    @State private var showReplacePanel = false
    @State private var replacement = ""

    private var selectedEntries: [Binding<SRTEntry>] {
        selection.compactMap { id in
            guard let index = file.entries.firstIndex(where: { $0.id == id }) else {
                return nil
            }

            return $file.entries[index]
        }
    }

    private var searchMatches: [SearchMatch] {
        guard !debouncedSearchQuery.isEmpty else {
            return []
        }

        var matches = [SearchMatch]()

        for entry in file.entries {
            if entry.content.isEmpty {
                continue
            }

            var searchRange = entry.content.startIndex..<entry.content.endIndex
            var options = String.CompareOptions()

            if !matchCase {
                options.insert(.caseInsensitive)
            }

            while let range = entry.content[searchRange].range(of: debouncedSearchQuery, options: options) {
                matches.append(SearchMatch(entryId: entry.id, range: range))
                searchRange = range.upperBound..<entry.content.endIndex
            }
        }

        return matches
    }

    private var matchCountLabel: String {
        searchMatches.isEmpty ? "0 matches" : "\(searchSelectionIndex + 1)/\(searchMatches.count)"
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                if showSearchPanel {
                    makeSearchPanel(scrollProxy: proxy)

                    if showReplacePanel {
                        makeReplacePanel(scrollProxy: proxy)
                    }
                }

                makeSubtitleTable(scrollProxy: proxy)
            }
            .animation(.easeInOut, value: showSearchPanel)
            .animation(.easeInOut, value: showReplacePanel)
        }
        .focusedSceneValue(\.entrySelection, $selection)
        .focusedSceneValue(\.showSubtitleOffsetSheet, $showSubtitleOffsetSheet)
        .focusedSceneValue(\.showLinearCorrectionSheet, $showLinearCorrectionSheet)
        .focusedSceneValue(\.showSearchPanel, $showSearchPanel)
        .inspector(isPresented: $showSubtitleInspector, content: makeSubtitleInspector)
        .sheet(isPresented: $showSubtitleOffsetSheet, content: makeSubtitleOffsetSheet)
        .sheet(isPresented: $showLinearCorrectionSheet, content: makeLinearCorrectionSheet)
    }

    private func makeSearchPanel(scrollProxy proxy: ScrollViewProxy) -> some View {
        HStack {
            SearchBarView(
                query: $searchQuery,
                matchCase: $matchCase
            ) {
                showSearchPanel.toggle()
            } onUpArrow: {
                selectPreviousSearchResult()
            } onDownArrow: {
                selectNextSearchResult()
            }

            HStack {
                Stepper(matchCountLabel) {
                    selectPreviousSearchResult()
                } onDecrement: {
                    selectNextSearchResult()
                }
                .disabled(searchMatches.isEmpty)

                Button("Done") {
                    showSearchPanel.toggle()
                }

                Toggle("Replace", isOn: $showReplacePanel)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }

    private func makeReplacePanel(scrollProxy proxy: ScrollViewProxy) -> some View {
        HStack {
            ReplaceBarView(replacement: $replacement) {
                showReplacePanel.toggle()
            } onUpArrow: {
                selectPreviousSearchResult()
            } onDownArrow: {
                selectNextSearchResult()
            } onEnter: {
                replaceCurrentSearchResult()
            }

            Button("Replace") {
                replaceCurrentSearchResult()
            }
            .disabled(searchMatches.isEmpty)

            Button("Replace All") {
                replaceAllSearchResults()
            }
            .disabled(searchMatches.isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }

    private func makeSubtitleTable(scrollProxy proxy: ScrollViewProxy) -> some View {
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
                Text(withSearchResultsHighlighted(entry: $0))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2.5)
            }
        } rows: {
            ForEach(file.entries) { entry in
                TableRow(entry)
            }
        }
        .task(id: searchQuery) {
            await updateDebouncedSearchQuery()
        }
        .onChange(of: searchSelectionIndex, { _, newValue in
            guard !searchMatches.isEmpty, newValue >= 0 else {
                return
            }

            let matchEntryId = searchMatches[newValue].entryId

            selection = [matchEntryId]

            withAnimation {
                proxy.scrollTo(matchEntryId, anchor: .center)
            }
        })
        .onChange(of: showSearchPanel) { _, newValue in
            guard newValue else {
                showReplacePanel = false
                replacement = ""
                searchSelectionIndex = -1

                return
            }

            guard !searchQuery.isEmpty else {
                return
            }

            searchSelectionIndex = 0
        }
        .onChange(of: matchCase) {
            guard !searchQuery.isEmpty else {
                return
            }

            // force scrolling if the first result is already selected
            if searchSelectionIndex == 0 {
                let matchEntryId = searchMatches[searchSelectionIndex].entryId

                selection = [matchEntryId]

                withAnimation {
                    proxy.scrollTo(matchEntryId, anchor: .center)
                }
            } else {
                searchSelectionIndex = 0
            }
        }
//        .onChange(of: selection) { _, newValue in
//            guard !searchMatches.isEmpty, newValue.count == 1 else {
//                return
//            }
//
//            guard let selectedEntryId = newValue.first,
//                  let matchIndex = searchMatches.firstIndex(where: { $0.entryId == selectedEntryId })
//            else {
//                return
//            }
//
//            searchSelectionIndex = matchIndex
//        }
        .contextMenu(forSelectionType: SRTEntry.ID.self, menu: makeSubtitleContextMenu)
        .copyable(selectedEntries.map(\.wrappedValue.content))
    }

    private func updateDebouncedSearchQuery() async {
        guard !searchQuery.isEmpty else {
            debouncedSearchQuery = ""

            return
        }

        try? await Task.sleep(for: .milliseconds(250))

        guard !Task.isCancelled else {
            return
        }

        debouncedSearchQuery = searchQuery

        guard !searchMatches.isEmpty else {
            return
        }

        searchSelectionIndex = 0
    }

    @ViewBuilder
    private func makeSubtitleInspector() -> some View {
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

    private func makeSubtitleOffsetSheet() -> some View {
        Section {
            SubtitleOffsetView(entries: selectedEntries, shouldDismiss: true)
        } header: {
            Text("Shift Time")
                .font(.headline)
        }
        .padding()
        .frame(minWidth: 300, maxWidth: 300)
    }

    private func makeLinearCorrectionSheet() -> some View {
        Section {
            LinearCorrectionSheetView(file: file)
        } header: {
            Text("Linear Correction")
                .font(.headline)
        }
        .padding()
        .frame(minWidth: 600, maxWidth: 600)
    }

    @ViewBuilder
    private func makeSubtitleContextMenu(for menuSelection: Set<SRTEntry.ID>) -> some View {
        // update the table selection according to the menu selection
        if selection != menuSelection {
            let _ = { selection = menuSelection }()
        }

        let menuEntries: [SRTEntry] = menuSelection.compactMap { id in
            guard let index = file.entries.firstIndex(where: { $0.id == id }) else {
                return nil
            }

            return file.entries[index]
        }

        if !menuEntries.isEmpty {
            // menu items for a single subtitle
            if menuEntries.count == 1, let entry = menuEntries.first {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.content, forType: .string)
                } label: {
                    Label("Copy Subtitle", systemImage: "doc.on.doc")
                }

                Divider()

                Button {
                    withAnimation {
                        guard let newEntry = file.insertEntry(after: entry) else {
                            return
                        }

                        selection = [newEntry.id]
                    }
                } label: {
                    Label("Insert Below", systemImage: "square.bottomthird.inset.filled")
                }

                Button {
                    withAnimation {
                        guard let newEntry = file.insertEntry(before: entry) else {
                            return
                        }

                        selection = [newEntry.id]
                    }
                } label: {
                    Label("Insert Above", systemImage: "square.topthird.inset.filled")
                }

                Divider()
            }

            // menu items for multiple subtitles
            Button {
                showSubtitleOffsetSheet.toggle()
            } label: {
                Label("Shift Time", systemImage: "timer")
            }

            Divider()

            Button(role: .destructive) {
                withAnimation {
                    file.deleteAll(entries: menuEntries)
                }

                selection.removeAll()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func selectPreviousSearchResult() {
        guard !searchMatches.isEmpty else {
            return
        }

        if searchSelectionIndex > searchMatches.startIndex {
            searchSelectionIndex -= 1
        } else {
            searchSelectionIndex = searchMatches.endIndex - 1
        }
    }

    private func selectNextSearchResult() {
        guard !searchMatches.isEmpty else {
            return
        }

        if searchSelectionIndex < searchMatches.endIndex - 1 {
            searchSelectionIndex += 1
        } else {
            searchSelectionIndex = searchMatches.startIndex
        }
    }

    private func replaceCurrentSearchResult() {
        guard !searchMatches.isEmpty else {
            return
        }

        let match = searchMatches[searchSelectionIndex]

        if let entry = $file.entries.first(where: { $0.wrappedValue.id == match.entryId }) {
            entry.wrappedValue.content.replaceSubrange(match.range, with: replacement)
        }

        // deselect if no more occurrences are left
        guard !searchMatches.isEmpty else {
            selection.removeAll()

            return
        }

        // select the first search result if the last has been replaced
        if searchSelectionIndex > searchMatches.endIndex - 1 {
            searchSelectionIndex = searchMatches.startIndex
        }
    }

    private func replaceAllSearchResults() {
        guard !searchMatches.isEmpty else {
            return
        }

        // deselect all
        selection.removeAll()

        let entryIds = Set(searchMatches.map { $0.entryId })

        var options = String.CompareOptions()

        if !matchCase {
            options.insert(.caseInsensitive)
        }

        for entry in $file.entries where entryIds.contains(entry.id) {
            entry.wrappedValue.content = entry.wrappedValue.content
                .replacingOccurrences(of: debouncedSearchQuery, with: replacement, options: options)
        }
    }

    private func withSearchResultsHighlighted(
        entry: SRTEntry,
        backgroundColor color: Color = .yellow.opacity(0.3),
        currentSelectionColor selectionColor: Color = .yellow.opacity(0.6)
    ) -> AttributedString {
        var attributed = AttributedString(entry.content)

        guard showSearchPanel, !searchMatches.isEmpty else {
            return attributed
        }

        var searchRange = attributed.startIndex..<attributed.endIndex
        var options = String.CompareOptions()

        if !matchCase {
            options.insert(.caseInsensitive)
        }

        while let range = attributed[searchRange].range(of: debouncedSearchQuery, options: options) {
            let selectedMatch = searchMatches[searchSelectionIndex]

            if let stringRange = Range<String.Index>(range, in: entry.content),
               stringRange == selectedMatch.range,
               entry.id == selectedMatch.entryId {
                attributed[range].backgroundColor = selectionColor
            } else {
                attributed[range].backgroundColor = color
            }

            searchRange = range.upperBound..<attributed.endIndex
        }

        return attributed
    }
}

fileprivate struct SearchMatch: Identifiable {
    let id = UUID()
    let entryId: UUID
    let range: Range<String.Index>
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
