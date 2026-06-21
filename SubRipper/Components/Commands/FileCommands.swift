//
//  FileCommands.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct FileCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    @FocusedValue(\.currentFile) private var currentFile
    @FocusedValue(\.showSubtitleInspector) private var showSubtitleInspector
    @FocusedValue(\.selectedEntries) private var selectedEntries
    @FocusedValue(\.showSubtitleOffsetSheet) private var showSubtitleOffsetSheet

    var store: SubRipperStore

    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button {
                if let showSubtitleInspector {
                    showSubtitleInspector.wrappedValue.toggle()
                }
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
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.srt]
                panel.allowsMultipleSelection = true
                panel.canChooseDirectories = false

                if panel.runModal() == .OK {
                    var isStartupOpen = true

                    for url in panel.urls {
                        let accessed = url.startAccessingSecurityScopedResource()

                        do {
                            let file = try store.load(url: url)

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

                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.srt]
                    panel.directoryURL = file.url.deletingLastPathComponent()
                    panel.nameFieldStringValue = file.url.lastPathComponent
                    panel.canCreateDirectories = true

                    if panel.runModal() == .OK, let url = panel.url {
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
                    guard let id = selectedEntries?.wrappedValue.first,
                          let entry = currentFile.entries.first(where: { $0.id == id }) else { return }

                    withAnimation {
                        currentFile.insertEntry(after: entry)
                    }
                }
                .disabled(selectedEntries?.wrappedValue.count != 1)

                Button("Insert Above", systemImage: "square.topthird.inset.filled") {
                    guard let id = selectedEntries?.wrappedValue.first,
                          let entry = currentFile.entries.first(where: { $0.id == id }) else { return }

                    withAnimation {
                        currentFile.insertEntry(before: entry)
                    }
                }
                .disabled(selectedEntries?.wrappedValue.count != 1)

                Divider()

                Button("Append", systemImage: "plus") {
                    currentFile.appendEntry()
                }

                Divider()

                Button("Shift Time", systemImage: "timer") {
                    if let showSubtitleOffsetSheet {
                        showSubtitleOffsetSheet.wrappedValue.toggle()
                    }
                }
                .disabled(selectedEntries?.wrappedValue.isEmpty ?? true)

                Divider()

                Button("Delete", systemImage: "trash") {
                    guard let selectedEntries else {
                        return
                    }

                    withAnimation {
                        currentFile.deleteAll { selectedEntries.wrappedValue.contains($0.id) }
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(selectedEntries?.wrappedValue.isEmpty ?? true)
            }
        }
    }
}
