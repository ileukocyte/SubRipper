//
//  FileCommands.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct FileCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.activeFile) private var activeFile

    var store: SubRipperStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(after: .newItem) {
            Button("Open...", systemImage: "arrow.up.right.square") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [SubRipperApp.srtType]
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
                guard let file = activeFile else { return }

                do {
                    try store.export(file: file)
                } catch {
                    Alerts.showDefaultErrorAlert(for: error)
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(activeFile == nil)
        }
    }
}
