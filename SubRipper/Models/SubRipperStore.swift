//
//  SubRipperStore.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import Foundation

@Observable
class SubRipperStore {
    var openFiles: [SrtFile] = []
    var hasOpenFiles: Bool { !openFiles.isEmpty }

    subscript(id: UUID) -> SrtFile? {
        openFiles.first { $0.id == id }
    }

    func load(url: URL) throws -> SrtFile {
        let content = try String(contentsOf: url, encoding: .utf8)
        let entries = try SrtMarshaler.unmarshal(from: content)
        let file = SrtFile(url: url, entries: entries)

        openFiles.append(file)

        return file
    }
    
    func remove(id: UUID) {
        openFiles.removeAll { $0.id == id }
    }

    func removeAll() {
        openFiles.removeAll()
    }

    func export(file: SrtFile, to url: URL? = nil) throws {
        let content = SrtMarshaler.marshal(file.entries)
        try content.write(to: url ?? file.url, atomically: true, encoding: .utf8)
    }

    func exportAll() throws {
        for file in openFiles {
            try export(file: file)
        }
    }
}
