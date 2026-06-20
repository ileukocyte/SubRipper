//
//  SrtMarshaler.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import Foundation

enum SrtMarshaler {
    // timestampRegex is used for interval timestamp validation, so digit count matching is not as strict
    static let timestampRegex = /(?<hours>\d*\d):(?<minutes>[0-5]?\d):(?<seconds>[0-5]?\d),(?<ms>\d{1,3})/
    static let entryRegex = /^(?<index>\d+)$\n^((?<startHours>\d{2,}):(?<startMinutes>[0-5]\d):(?<startSeconds>[0-5]\d),(?<startMs>\d{3})) --> ((?<endHours>\d{2,}):(?<endMinutes>[0-5]\d):(?<endSeconds>[0-5]\d),(?<endMs>\d{3}))$\n(?<content>^.+$(\n^.+$)*)/
        .anchorsMatchLineEndings()

    static func parseTime(formatted: String) throws -> TimeInterval {
        guard let match = try? timestampRegex.wholeMatch(in: formatted) else {
            throw SrtParseError.invalidTimeComponent(formatted)
        }

        return try Self.parseTime(match.hours, match.minutes, match.seconds, match.ms)
    }

    static func parseTime(
        _ hours: Substring,
        _ minutes: Substring,
        _ seconds: Substring,
        _ milliseconds: Substring
    ) throws -> TimeInterval {
        let millisecondsTrailingZeros = if milliseconds.count == 3 {
            milliseconds
        } else {
            milliseconds + String(repeating: "0", count: 3 - milliseconds.count)
        }

        guard let h = Double(hours),
              let m = Double(minutes),
              let s = Double(seconds),
              let ms = Double(millisecondsTrailingZeros)
        else {
            throw SrtParseError.invalidTimeComponent("\(hours):\(minutes):\(seconds),\(millisecondsTrailingZeros)")
        }

        return h * 3600 + m * 60 + s + ms / 1000
    }

    static func formatTime(_ interval: TimeInterval) -> String {
        let totalMs = Int((interval * 1000).rounded())
        let ms = totalMs % 1000
        let totalSeconds = totalMs / 1000
        let seconds = totalSeconds % 60
        let totalMinutes = totalSeconds / 60
        let minutes = totalMinutes % 60
        let hours = totalMinutes / 60

        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, ms)
    }

    static func unmarshal(from data: String) throws -> [SrtEntry] {
        let normalizedData = data
            .trimmingCharacters(in: .init(charactersIn: "\u{feff}"))
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return try normalizedData.matches(of: entryRegex).map { match in
            guard let index = Int(match.index) else {
                throw SrtParseError.invalidIndex(String(match.index))
            }

            let startTime = try Self.parseTime(match.startHours, match.startMinutes, match.startSeconds, match.startMs)
            let endTime = try Self.parseTime(match.endHours, match.endMinutes, match.endSeconds, match.endMs)
            let content = match.content
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            return SrtEntry(
                index: index,
                startTime: startTime,
                endTime: endTime,
                content: content
            )
        }
    }

    static func marshal(_ entries: [SrtEntry]) -> String {
        return entries.map { entry in
            "\(entry.index)\n" +
            "\(Self.formatTime(entry.startTime)) --> \(Self.formatTime(entry.endTime))\n" +
            entry.content
        }.joined(separator: "\n\n")
    }
}
