//
//  SubRipperTests.swift
//  SubRipperTests
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import Foundation
import Testing
@testable import SubRipper

struct SubRipperTests {
    private let content = """
1
00:00:28,571 --> 00:00:31,658
(door opens)

2
00:00:31,825 --> 00:00:33,785
(door closes)

3
00:00:33,952 --> 00:00:36,788
(approaching footsteps)

4
00:00:41,876 --> 00:00:43,545
Mom?

5
00:00:46,089 --> 00:00:48,466
- Kat?

6
00:00:49,467 --> 00:00:52,846
Yeah. I'm fine.

7
00:00:54,264 --> 00:00:56,266
Why are you
all dressed up?

8
00:00:56,433 --> 00:00:58,351
What do you mean?
"""

    // MARK: - SubRipper tests
    @MainActor
    @Test func unmarshalThenMarshal() throws {
        let entries = try SRTMarshaler.unmarshal(from: content)
        let rebuiltContent = SRTMarshaler.marshal(entries)

        #expect(content == rebuiltContent)
        #expect(entries.count == 8)
        #expect(entries.map(\.index).elementsEqual(1...8))
        #expect(entries[2].content == "(approaching footsteps)")
        #expect(timeIntervalApproximatelyEqual(entries[7].startTime, 56.433, tolerance: .ulpOfOne))
    }

    @MainActor
    @Test func applyLinearCorrectionIdempotent() async throws {
        let file = try await makeSRTFile()

        file.applyLinearCorrection(startTime: 28.571, endTime: 58.351)
        #expect(timeIntervalApproximatelyEqual(file.entries[0].endTime, 31.658, tolerance: .ulpOfOne))
    }

    @MainActor
    @Test func applyLinearCorrection2sShift() async throws {
        let file = try await makeSRTFile()

        file.applyLinearCorrection(startTime: 30.571, endTime: 60.351)
        #expect(timeIntervalApproximatelyEqual(file.entries[0].endTime, 33.658))
    }

    @MainActor
    @Test func applyLinearCorrectionStretching() async throws {
        let file = try await makeSRTFile()

        // stretching
        file.applyLinearCorrection(startTime: 28.571, endTime: 116.702)
        #expect(timeIntervalApproximatelyEqual(file.entries[0].startTime, 28.571))
        #expect(timeIntervalApproximatelyEqual(file.entries[0].endTime, 37.707))
        #expect(timeIntervalApproximatelyEqual(file.entries[1].startTime, 38.201))
        #expect(timeIntervalApproximatelyEqual(file.entries[1].endTime, 44.001))
        #expect(timeIntervalApproximatelyEqual(file.entries[2].startTime, 44.496))
        #expect(timeIntervalApproximatelyEqual(file.entries[2].endTime, 52.888))
        #expect(timeIntervalApproximatelyEqual(file.entries[5].startTime, 90.411))
        #expect(timeIntervalApproximatelyEqual(file.entries[5].endTime, 100.410))
        #expect(timeIntervalApproximatelyEqual(file.entries[6].startTime, 104.607))
        #expect(timeIntervalApproximatelyEqual(file.entries[6].endTime, 110.532))
        #expect(timeIntervalApproximatelyEqual(file.entries[7].startTime, 111.026))
        #expect(timeIntervalApproximatelyEqual(file.entries[7].endTime, 116.702))

        // rollback
        file.applyLinearCorrection(startTime: 28.571, endTime: 58.351)
        #expect(content == SRTMarshaler.marshal(file.entries))
    }

    // MARK: - helper functions
    private func makeSRTFile() async throws -> SRTFile {
        await .init(
            url: URL(fileURLWithPath: "A Heart in Winter (1992).srt"),
            entries: try await SRTMarshaler.unmarshal(from: content),
            originalContent: content
        )
    }

    private func timeIntervalApproximatelyEqual(
        _ actual: TimeInterval,
        _ expected: TimeInterval,
        tolerance: TimeInterval = 0.0005
    ) -> Bool {
        abs(actual - expected) < tolerance
    }
}
