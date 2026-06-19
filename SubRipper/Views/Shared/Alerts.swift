//
//  Alerts.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import AppKit

enum Alerts {
    @MainActor
    static func showDefaultErrorAlert(for error: any Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
