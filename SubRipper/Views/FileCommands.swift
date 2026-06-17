//
//  FileCommands.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct FileCommands: Commands {
    @Environment(\.openWindow) private var openWindow

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

                        let alert = NSAlert(error: error)
                        alert.runModal()
                    }
                }
            }
            .keyboardShortcut("o", modifiers: .command)
        }
    }
}
