//
//  SubRipperStore.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

@Observable
class SubRipperStore {
    var openFiles: [SrtFile] = []
    var hasOpenFiles: Bool { !openFiles.isEmpty }

    subscript(id: UUID) -> SrtFile? {
        openFiles.first { $0.id == id }
    }

    func load(url: URL) throws -> SrtFile {
        let content = try String(contentsOf: url, encoding: .utf8)
        let entries = try SrtMarshaler.unmarshal(content)
        let file = SrtFile(url: url, entries: entries)

        openFiles.append(file)

        return file
    }
    
    func remove(id: UUID) {
        openFiles.removeAll { $0.id == id }
    }
}

struct SrtFile: Identifiable {
    let id = UUID()
    let url: URL
    var entries: [SrtEntry]
}
