//
//  Keys.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/20/2026.
//

import AppKit

enum Keys {
    static func allModifiersPressed(_ modifiers: [NSEvent.ModifierFlags]) -> Bool {
        let flags = NSEvent.modifierFlags
        let required = modifiers.reduce(NSEvent.ModifierFlags()) { $0.union($1) }

        return flags.contains(required)
    }
}
