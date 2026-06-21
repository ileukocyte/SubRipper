//
//  SrtFile.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import SwiftUI

@Observable
class SrtFile: Identifiable {
    let id = UUID()
    var url: URL
    var entries: [SrtEntry]
    var originalContent: String

    init(url: URL, entries: [SrtEntry], originalContent: String) {
        self.url = url
        self.entries = entries
        self.originalContent = originalContent
    }

    func appendEntry() {
        let new = SrtEntry(
            index: (entries.last?.index ?? 0) + 1,
            startTime: entries.last?.endTime ?? 0,
            endTime: entries.last?.endTime ?? 0,
            content: ""
        )

        entries.append(new)
    }

    func insertEntry(after: SrtEntry) {
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

    func insertEntry(before: SrtEntry) {
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

        entries.remove(atOffsets: IndexSet(indices))

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }
    }
}
