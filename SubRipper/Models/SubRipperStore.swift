//
//  SubRipperStore.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import Foundation

@Observable
class SubRipperStore {
    var openFiles: [SRTFile] = []
    var hasOpenFiles: Bool { !openFiles.isEmpty }

    subscript(id: UUID) -> SRTFile? {
        openFiles.first { $0.id == id }
    }

    subscript(url: URL) -> SRTFile? {
        openFiles.first { $0.url == url }
    }

    func load(url: URL, encoding: String.Encoding = .utf8) throws -> SRTFile {
        if let file = self[url] {
            return file
        }

        let content = try String(contentsOf: url, encoding: encoding)
        let entries = try SRTMarshaler.unmarshal(from: content)
        let file = SRTFile(url: url, entries: entries, originalContent: content)

        openFiles.append(file)

        return file
    }
    
    func remove(id: UUID) {
        openFiles.removeAll { $0.id == id }
    }

    func removeAll() {
        openFiles.removeAll()
    }

    func export(file: SRTFile, to url: URL? = nil) throws {
        let content = SRTMarshaler.marshal(file.entries)
        try content.write(to: url ?? file.url, atomically: true, encoding: .utf8)

        file.originalContent = content

        if let url {
            file.url = url
        }
    }

    func exportAll() throws {
        for file in openFiles {
            try export(file: file)
        }
    }
}
