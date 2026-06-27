//
//  SRTFile.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import SwiftUI

@Observable
class SRTFile: Identifiable {
    let id = UUID()
    var url: URL
    var entries: [SRTEntry]
    var originalContent: String

    init(url: URL, entries: [SRTEntry], originalContent: String) {
        self.url = url
        self.entries = entries
        self.originalContent = originalContent
    }

    @discardableResult
    func appendEntry() -> SRTEntry {
        let entry = SRTEntry(
            index: (entries.last?.index ?? 0) + 1,
            startTime: entries.last?.endTime ?? 0,
            endTime: entries.last?.endTime ?? 0,
            content: ""
        )

        entries.append(entry)

        return entry
    }

    @discardableResult
    func insertEntry(after previous: SRTEntry) -> SRTEntry? {
        guard let index = entries.firstIndex(of: previous) else {
            return nil
        }

        let entry = SRTEntry(
            index: previous.index,
            startTime: previous.endTime,
            endTime: previous.endTime,
            content: ""
        )

        entries.insert(entry, at: index + 1)

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }

        return entry
    }

    @discardableResult
    func insertEntry(before next: SRTEntry) -> SRTEntry? {
        guard let index = entries.firstIndex(of: next) else {
            return nil
        }

        let entry = SRTEntry(
            index: next.index,
            startTime: next.startTime,
            endTime: next.startTime,
            content: ""
        )

        entries.insert(entry, at: index)

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }

        return entry
    }

    func deleteAll(entries toDelete: [SRTEntry]) {
        let indices = toDelete.compactMap { entries.firstIndex(of: $0) }.sorted(by: <)

        entries.remove(atOffsets: IndexSet(indices))

        for i in 0..<entries.count {
            entries[i].index = i + 1
        }
    }

    func deleteAll(where predicate: (SRTEntry) -> Bool) {
        deleteAll(entries: entries.filter(predicate))
    }

    func applyLinearCorrection(
        startTime correctedStartTime: TimeInterval,
        endTime correctedEndTime: TimeInterval
    ) {
        guard entries.count >= 2,
              let first = entries.first,
              let last = entries.last,
              last.endTime != first.startTime
        else {
            return
        }

        let scale = (correctedEndTime - correctedStartTime) / (last.endTime - first.startTime)
        let offset = correctedStartTime - scale * first.startTime

        for (i, entry) in entries.enumerated() {
            entries[i].startTime = entry.startTime * scale + offset
            entries[i].endTime = entry.endTime * scale + offset
        }
    }
}
