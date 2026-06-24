//
//  FilePanels.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/24/2026.
//

import AppKit

enum FilePanels {
    static func openNSOpenPanel(handler: ([URL], String.Encoding) throws -> Void) rethrows {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.srt]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        let encodingView = EncodingAccessoryViewController()
        panel.accessoryView = encodingView.view

        if panel.runModal() == .OK {
            try handler(panel.urls, encodingView.selection)
        }
    }

    static func openNSSavePanel(for url: URL, handler: (URL) throws -> Void) rethrows {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.srt]
        panel.directoryURL = url.deletingLastPathComponent()
        panel.nameFieldStringValue = url.lastPathComponent
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try handler(url)
        }
    }
}

class EncodingAccessoryViewController: NSViewController {
    static let encodings: [(String, String.Encoding)] = [
        ("Unicode (UTF-8)", .utf8),
        ("Cyrillic (Windows-1251)", .windowsCP1251),
        ("Western (Windows-1252)", .windowsCP1252),
        ("Western (ISO 8859-1)", .isoLatin1),
    ]

    private let popUp = NSPopUpButton()

    var selection: String.Encoding {
        Self.encodings[popUp.indexOfSelectedItem].1
    }

    override func loadView() {
        popUp.addItems(withTitles: Self.encodings.map(\.0))
        popUp.selectItem(at: 0)

        let label = NSTextField(labelWithString: "File Encoding:")
        let stack = NSStackView(views: [label, popUp])
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        self.view = stack
    }
}
