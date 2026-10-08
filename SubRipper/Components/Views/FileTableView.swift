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
    @State private var searchSelectionIndex = -1
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

            while let range = entry.content[searchRange].range(of: debouncedSearchQuery, options: searchOptions) {
                matches.append(SearchMatch(entryId: entry.id, range: range))
                searchRange = range.upperBound..<entry.content.endIndex
            }
        }

        return matches
    }

    private var searchOptions: String.CompareOptions {
        var options = String.CompareOptions()

        if !matchCase {
            options.insert(.caseInsensitive)
        }

        return options
    }

    private var matchCountLabel: String {
        searchMatches.indices.contains(searchSelectionIndex) ? "\(searchSelectionIndex + 1)/\(searchMatches.count)" : "0 matches"
    }

    // MARK: - view builders
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
                selectPreviousSearchResult(scrollProxy: proxy)
            } onDownArrow: {
                selectNextSearchResult(scrollProxy: proxy)
            }

            HStack {
                Stepper(matchCountLabel) {
                    selectPreviousSearchResult(scrollProxy: proxy)
                } onDecrement: {
                    selectNextSearchResult(scrollProxy: proxy)
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
                selectPreviousSearchResult(scrollProxy: proxy)
            } onDownArrow: {
                selectNextSearchResult(scrollProxy: proxy)
            } onEnter: {
                replaceCurrentSearchResult(scrollProxy: proxy)
            }

            Button("Replace") {
                replaceCurrentSearchResult(scrollProxy: proxy)
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
            await updateDebouncedSearchQuery(scrollProxy: proxy)
        }
        .onChange(of: searchSelectionIndex, { _, newValue in
            focusCurrentMatch(scrollProxy: proxy)
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
            guard !searchMatches.isEmpty else {
                return
            }

            // force scrolling if the first result is already selected
            if searchSelectionIndex == 0 {
                focusCurrentMatch(scrollProxy: proxy)
            } else {
                searchSelectionIndex = 0
            }
        }
        // TODO: implement search match index updates on MANUAL selection change
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
            if menuEntries.count == 1, let entry = menuEntries.first {
                makeSingleEntrySubmenu(for: entry)

                Divider()
            }

            makeMultipleEntriesSubmenu(for: menuEntries)
        }
    }

    @ViewBuilder
    private func makeSingleEntrySubmenu(for entry: SRTEntry) -> some View {
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
    }

    @ViewBuilder
    private func makeMultipleEntriesSubmenu(for entries: [SRTEntry]) -> some View {
        Button {
            showSubtitleOffsetSheet.toggle()
        } label: {
            Label("Shift Time", systemImage: "timer")
        }

        Divider()

        Button(role: .destructive) {
            withAnimation {
                file.deleteAll(entries: entries)
            }

            selection.removeAll()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - search actions
    private func updateDebouncedSearchQuery(scrollProxy proxy: ScrollViewProxy) async {
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

        if searchSelectionIndex == 0 {
            focusCurrentMatch(scrollProxy: proxy)
        } else {
            searchSelectionIndex = 0
        }
    }

    private func selectPreviousSearchResult(scrollProxy proxy: ScrollViewProxy) {
        let matches = searchMatches

        guard !matches.isEmpty else {
            return
        }

        let current = min(searchSelectionIndex, matches.count - 1)
        let next = current > 0 ? current - 1 : matches.count - 1

        if searchSelectionIndex == next {
            focusCurrentMatch(scrollProxy: proxy)
        } else {
            searchSelectionIndex = next
        }
    }

    private func selectNextSearchResult(scrollProxy proxy: ScrollViewProxy) {
        let matches = searchMatches

        guard !matches.isEmpty else {
            return
        }

        let current = min(searchSelectionIndex, matches.count - 1)
        let next = current < matches.count - 1 ? current + 1 : 0

        if searchSelectionIndex == next {
            focusCurrentMatch(scrollProxy: proxy)
        } else {
            searchSelectionIndex = next
        }
    }

    // MARK: - replace actions
    private func replaceCurrentSearchResult(scrollProxy proxy: ScrollViewProxy) {
        var matches = searchMatches

        guard !debouncedSearchQuery.isEmpty, matches.indices.contains(searchSelectionIndex) else {
            return
        }

        let match = matches[searchSelectionIndex]

        guard let entryIndex = file.entries.firstIndex(where: { $0.id == match.entryId }) else {
            return
        }

        let offset = countSubstringOcurrences(of: debouncedSearchQuery, in: replacement)

        file.entries[entryIndex].content.replaceSubrange(match.range, with: replacement)

        matches = searchMatches

        // deselect if no more occurrences are left
        guard !matches.isEmpty else {
            selection.removeAll()
            searchSelectionIndex = 0

            return
        }

        var index = searchSelectionIndex + offset

        // select the first search result if the last has been replaced
        if index > matches.endIndex - 1 {
            index = matches.startIndex
        }

        if index == searchSelectionIndex {
            // force scrolling because the index didn't change
            focusCurrentMatch(scrollProxy: proxy)
        } else {
            searchSelectionIndex = index
        }
    }

    private func replaceAllSearchResults() {
        guard !searchMatches.isEmpty else {
            return
        }

        // deselect all
        selection.removeAll()

        let entryIds = Set(searchMatches.map { $0.entryId })

        for entry in $file.entries where entryIds.contains(entry.id) {
            entry.wrappedValue.content = entry.wrappedValue.content
                .replacingOccurrences(of: debouncedSearchQuery, with: replacement, options: searchOptions)
        }

        searchSelectionIndex = 0
    }

    // MARK: - search and replace utility functions
    private func countSubstringOcurrences(of substring: String, in value: String) -> Int {
        var count = 0
        var searchRange = value.startIndex..<value.endIndex

        while let range = value[searchRange].range(of: substring, options: searchOptions) {
            count += 1
            searchRange = range.upperBound..<value.endIndex
        }

        return count
    }

    private func focusCurrentMatch(scrollProxy proxy: ScrollViewProxy) {
        let matches = searchMatches

        guard matches.indices.contains(searchSelectionIndex) else {
            return
        }

        let matchEntryId = matches[searchSelectionIndex].entryId

        selection = [matchEntryId]

        withAnimation {
            proxy.scrollTo(matchEntryId, anchor: .center)
        }
    }

    private func withSearchResultsHighlighted(
        entry: SRTEntry,
        backgroundColor color: Color = .yellow.opacity(0.3),
        currentSelectionColor selectionColor: Color = .yellow.opacity(0.6)
    ) -> AttributedString {
        let matches = searchMatches

        var attributed = AttributedString(entry.content)

        guard showSearchPanel, matches.indices.contains(searchSelectionIndex) else {
            return attributed
        }

        var searchRange = attributed.startIndex..<attributed.endIndex

        let selectedMatch = matches[searchSelectionIndex]

        while let range = attributed[searchRange].range(of: debouncedSearchQuery, options: searchOptions) {
            if entry.id == selectedMatch.entryId,
               let stringRange = Range<String.Index>(range, in: entry.content),
               stringRange == selectedMatch.range {
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
