//
//  SrtMarshaler.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import Foundation
import RegexBuilder

enum SrtParseError: Error {
    case invalidIndex(String)
    case invalidTimeComponent(String)
}

enum SrtMarshaler {
    static let timestampRegex = /((?<hours>\d{2,}):(?<minutes>\d{2}):(?<seconds>\d{2}),(?<ms>\d{3}))/
    static let entryRegex = /^(?<index>\d+)$\n^((?<startHours>\d{2,}):(?<startMinutes>\d{2}):(?<startSeconds>\d{2}),(?<startMs>\d{3})) --> ((?<endHours>\d{2,}):(?<endMinutes>\d{2}):(?<endSeconds>\d{2}),(?<endMs>\d{3}))$\n(?<content>^.+$(\n^.+$)*)/
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
        guard let h = Double(hours),
              let m = Double(minutes),
              let s = Double(seconds),
              let ms = Double(milliseconds)
        else {
            throw SrtParseError.invalidTimeComponent("\(hours):\(minutes):\(seconds),\(milliseconds)")
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

    static func unmarshal(_ data: String) throws -> [SrtEntry] {
        let normalizedData = data
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return try normalizedData.matches(of: entryRegex).map { match in
            guard let index = Int(match.index) else {
                throw SrtParseError.invalidIndex(String(match.1))
            }

            let startTime = try Self.parseTime(match.startHours, match.startMinutes, match.startSeconds, match.startMs)
            let endTime = try Self.parseTime(match.endHours, match.endMinutes, match.endSeconds, match.endMs)
            let text = match.content.trimmingCharacters(in: .whitespacesAndNewlines)

            return SrtEntry(
                index: index,
                startTime: startTime,
                endTime: endTime,
                content: text
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
