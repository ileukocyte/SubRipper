//
//  SubRipperTests.swift
//  SubRipperTests
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import Testing
@testable import SubRipper

struct SubRipperTests {
    @Test func unmarshalThenMarshal() async throws {
        let content = """
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
        let entries = try await SrtMarshaler.unmarshal(content)
        let rebuiltContent = await SrtMarshaler.marshal(entries)

        #expect(content == rebuiltContent)
        #expect(entries.count == 8)
        #expect(entries.map(\.index).elementsEqual(1...8))
    }
}
