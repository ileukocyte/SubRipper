//
//  NSApplicationExtensions.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import AppKit

extension NSApplication {
    func centerWindow(id: String) {
        DispatchQueue.main.async {
            guard let window = self.windows.first(where: { $0.identifier?.rawValue == id }),
                  let screen = window.screen ?? NSScreen.main else { return }

            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame

            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func closeWindow(id: String) {
        DispatchQueue.main.async {
            self.windows.first { $0.identifier?.rawValue == id }?.close()
        }
    }

    func maximizeWindow(id: String?) {
        DispatchQueue.main.async {
            guard let window = self.windows.first(where: {
                if let id {
                    return $0.identifier?.rawValue == id
                }

                return $0.isKeyWindow
            }), let screen = window.screen ?? NSScreen.main else { return }

            window.setFrame(screen.visibleFrame, display: true)
        }
    }
}
