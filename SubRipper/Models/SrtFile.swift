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

    func insertNew(after: SrtEntry) {
        guard let index = entries.firstIndex(of: after) else {
            return
        }

        let new = SrtEntry(
            index: after.index,
            startTime: after.endTime,
            endTime: after.endTime,
            content: ""
        )

        entries.insert(new, at: index + 1)

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }
    }

    func insertNew(before: SrtEntry) {
        guard let index = entries.firstIndex(of: before) else {
            return
        }

        let new = SrtEntry(
            index: before.index,
            startTime: before.startTime,
            endTime: before.startTime,
            content: ""
        )

        entries.insert(new, at: index)

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }
    }

    func deleteAll(entries toDelete: [SrtEntry]) {
        let indices = toDelete.compactMap { entries.firstIndex(of: $0) }.sorted(by: <)

        for (offset, index) in indices.enumerated() {
            entries.remove(at: index - offset)
        }

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }
    }
}
