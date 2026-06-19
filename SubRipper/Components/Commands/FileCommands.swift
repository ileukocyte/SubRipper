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
    }
}
