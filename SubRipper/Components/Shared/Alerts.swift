//
//  Alerts.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import AppKit

enum Alerts {
    @MainActor
    @discardableResult
    static func showDefaultErrorAlert(for error: any Error) -> NSApplication.ModalResponse {
        let alert = NSAlert(error: error)

        return alert.runModal()
    }
}
