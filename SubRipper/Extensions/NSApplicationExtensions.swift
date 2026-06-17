//
//  NSApplicationExtensions.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import AppKit

extension NSApplication {
    @MainActor
    func centerWindow(id: String) {
        guard let window = self.windows.first(where: { $0.identifier?.rawValue == id }),
              let screen = window.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    @MainActor
    func closeWindow(id: String) {
        self.windows.first { $0.identifier?.rawValue == id }?.close()
    }

    @MainActor
    func maximizeWindow(id: String?) {
        guard let window = self.windows.first(where: {
            if let id {
                return $0.identifier?.rawValue == id
            }

            return $0.isKeyWindow
        }), let screen = window.screen ?? NSScreen.main else { return }

        window.setFrame(screen.visibleFrame, display: true)
    }
}
