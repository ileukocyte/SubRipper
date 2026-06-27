//
//  FileCommands.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct FileCommands: Commands {
    var store: SubRipperStore

    @Environment(\.openWindow) private var openWindow

    @FocusedValue(\.currentFile) private var currentFile
    @FocusedValue(\.entrySelection) private var entrySelection
    @FocusedValue(\.showSubtitleInspector) private var showSubtitleInspector
    @FocusedValue(\.showSubtitleOffsetSheet) private var showSubtitleOffsetSheet
    @FocusedValue(\.showLinearCorrectionSheet) private var showLinearCorrectionSheet

    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button {
                showSubtitleInspector?.wrappedValue.toggle()
            } label: {
                let isExpanded = showSubtitleInspector?.wrappedValue ?? false

                Label("\(isExpanded ? "Hide" : "Show") Inspector", systemImage: "sidebar.right")
            }
            .keyboardShortcut("i", modifiers: [.option, .command])
            .disabled(currentFile == nil)

            Divider()
        }

        CommandGroup(replacing: .newItem) {
            Button("Open...", systemImage: "arrow.up.right.square") {
                FilePanels.openNSOpenPanel { urls, encoding in
                    var isStartupOpen = true

                    for url in urls {
                        let accessed = url.startAccessingSecurityScopedResource()

                        do {
                            let file = try store.load(url: url, encoding: encoding)

                            if isStartupOpen {
                                NSApp.closeWindow(id: "startup")
                                isStartupOpen = false
                            }

                            openWindow(id: "file", value: file.id)
                        } catch {
                            if accessed {
                                url.stopAccessingSecurityScopedResource()
                            }

                            Alerts.showDefaultErrorAlert(for: error)
                        }
                    }
                }
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("Save", systemImage: "square.and.arrow.down") {
                guard let file = currentFile else {
                    return
                }

                do {
                    try store.export(file: file)
                } catch {
                    Alerts.showDefaultErrorAlert(for: error)
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(currentFile == nil)
            .modifierKeyAlternate(.option) {
                Button("Save As...", systemImage: "square.and.arrow.down") {
                    guard let file = currentFile else {
                        return
                    }

                    FilePanels.openNSSavePanel(for: file.url) { url in
                        do {
                            try store.export(file: file, to: url)
                        } catch {
                            Alerts.showDefaultErrorAlert(for: error)
                        }
                    }
                }
                .disabled(currentFile == nil)
            }
            .modifierKeyAlternate([.option, .shift]) {
                Button("Save All", systemImage: "square.and.arrow.down") {
                    do {
                        try store.exportAll()
                    } catch {
                        Alerts.showDefaultErrorAlert(for: error)
                    }
                }
                .disabled(currentFile == nil)
            }
        }

        if let currentFile {
            CommandMenu("Subtitles") {
                Button("Insert Below", systemImage: "square.bottomthird.inset.filled") {
                    guard let id = entrySelection?.wrappedValue.first,
                          let entry = currentFile.entries.first(where: { $0.id == id }) else { return }

                    withAnimation {
                        guard let newEntry = currentFile.insertEntry(after: entry) else {
                            return
                        }

                        entrySelection?.wrappedValue = [newEntry.id]
                    }
                }
                .disabled(entrySelection?.wrappedValue.count != 1)

                Button("Insert Above", systemImage: "square.topthird.inset.filled") {
                    guard let id = entrySelection?.wrappedValue.first,
                          let entry = currentFile.entries.first(where: { $0.id == id }) else { return }

                    withAnimation {
                        guard let newEntry = currentFile.insertEntry(before: entry) else {
                            return
                        }

                        entrySelection?.wrappedValue = [newEntry.id]
                    }
                }
                .disabled(entrySelection?.wrappedValue.count != 1)

                Divider()

                Button("Append", systemImage: "plus") {
                    withAnimation {
                        let entry = currentFile.appendEntry()
                        entrySelection?.wrappedValue = [entry.id]
                    }
                }

                Divider()

                Button("Shift Time", systemImage: "timer") {
                    showSubtitleOffsetSheet?.wrappedValue.toggle()
                }
                .disabled(entrySelection?.wrappedValue.isEmpty ?? true)

                Button("Linear Correction", systemImage: "graph.2d") {
                    entrySelection?.wrappedValue.removeAll()
                    showLinearCorrectionSheet?.wrappedValue.toggle()
                }
                .disabled(currentFile.entries.count < 2)

                Divider()

                Button("Delete", systemImage: "trash") {
                    guard let entrySelection else {
                        return
                    }

                    withAnimation {
                        currentFile.deleteAll { entrySelection.wrappedValue.contains($0.id) }
                    }

                    entrySelection.wrappedValue.removeAll()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(entrySelection?.wrappedValue.isEmpty ?? true)
            }
        }
    }
}
