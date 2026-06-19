//
//  SrtFile.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import Foundation

@Observable
class SrtFile: Identifiable {
    let id = UUID()
    let url: URL
    var entries: [SrtEntry]

    init(url: URL, entries: [SrtEntry]) {
        self.url = url
        self.entries = entries
    }
}
