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
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false

                if panel.runModal() == .OK, let url = panel.url {
                    let accessed = url.startAccessingSecurityScopedResource()

                    do {
                        let file = try store.load(url: url)

                        NSApp.closeWindow(id: "startup")
                        openWindow(id: "file", value: file.id)
                    } catch {
                        if accessed {
                            url.stopAccessingSecurityScopedResource()
                        }

                        Alerts.showDefaultErrorAlert(for: error)
                    }
                }
            }
            .keyboardShortcut("o", modifiers: .command)

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
        }

        if currentFile != nil {
            CommandMenu("Subtitles") {
                Button("Insert Below", systemImage: "square.bottomthird.inset.filled") {
                    guard let currentFile,
                          let id = selectedEntries?.first,
                          let entry = currentFile.entries.first(where: { $0.id == id }) else { return }

                    currentFile.insertNew(after: entry)
                }
                .disabled(selectedEntries?.count != 1)

                Button("Insert Above", systemImage: "square.topthird.inset.filled") {
                    guard let currentFile,
                          let id = selectedEntries?.first,
                          let entry = currentFile.entries.first(where: { $0.id == id }) else { return }

                    currentFile.insertNew(before: entry)
                }
                .disabled(selectedEntries?.count != 1)

                Divider()

                Button("Shift Time", systemImage: "timer") {
                    if let showSubtitleOffsetSheet {
                        showSubtitleOffsetSheet.wrappedValue.toggle()
                    }
                }
                .disabled(selectedEntries?.isEmpty ?? true)

                Divider()

                Button("Delete", systemImage: "trash") {
                    guard let currentFile, let selectedEntries else {
                        return
                    }

                    currentFile.deleteAll(entries: currentFile.entries.filter { selectedEntries.contains($0.id) })
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(selectedEntries?.isEmpty ?? true)
            }
        }
    }
}
