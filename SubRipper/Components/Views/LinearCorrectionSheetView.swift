//
//  LinearCorrectionSheetView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/22/2026.
//

import SwiftUI

struct LinearCorrectionSheetView: View {
    private var initialStartTime: TimeInterval = 0
    private var initialEndTime: TimeInterval = 0

    @Environment(\.dismiss) private var dismiss

    @Bindable var file: SRTFile

    @State private var startTime: TimeInterval
    @State private var endTime: TimeInterval
    @State private var startTimePopover = false
    @State private var endTimePopover = false

    init(file: SRTFile) {
        self.file = file

        if let startTime = file.entries.first?.startTime {
            self.initialStartTime = startTime
        }

        if let endTime = file.entries.last?.endTime {
            self.initialEndTime = endTime
        }

        self._startTime = State(initialValue: initialStartTime)
        self._endTime = State(initialValue: initialEndTime)
    }

    private var canSave: Bool {
        guard let first = file.entries.first,
              let last = file.entries.last,
              last.endTime != first.startTime
        else {
            return false
        }

        guard endTime > startTime else {
            return false
        }

        return startTime != initialStartTime || endTime != initialEndTime
    }

    var body: some View {
        HStack {
            VStack {
                Form {
                    Section(header: Text("Current")) {
                        LabeledContent("File Start") {
                            Text(SRTMarshaler.formatTime(initialStartTime))
                                .textSelection(.enabled)
                                .fontDesign(.monospaced)
                        }

                        LabeledContent("File End") {
                            Text(SRTMarshaler.formatTime(initialEndTime))
                                .textSelection(.enabled)
                                .fontDesign(.monospaced)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack {
                Form {
                    Section(header: Text("Correction")) {
                        Button {
                            startTimePopover.toggle()
                        } label: {
                            LabeledContent("File Start") {
                                Text(SRTMarshaler.formatTime(startTime))
                                    .fontDesign(.monospaced)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .onHover { inView in
                            if inView {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .popover(isPresented: $startTimePopover) {
                            TimestampPopoverView(timestamp: $startTime, heading: "Start Time")
                        }

                        Button {
                            endTimePopover.toggle()
                        } label: {
                            LabeledContent("File End") {
                                Text(SRTMarshaler.formatTime(endTime))
                                    .fontDesign(.monospaced)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .onHover { inView in
                            if inView {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .popover(isPresented: $endTimePopover) {
                            TimestampPopoverView(timestamp: $endTime, heading: "End Time")
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
            .frame(maxWidth: .infinity)
        }

        Divider()

        HStack {
            Button("Cancel") {
                dismiss()
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)

            Button("Apply") {
                file.applyLinearCorrection(startTime: startTime, endTime: endTime)
                dismiss()
            }
            .disabled(!canSave)
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let url = URL(fileURLWithPath: "A Heart in Winter (1992).srt")
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

    Section {
        LinearCorrectionSheetView(
            file: SRTFile(
                url: url,
                entries: try! SRTMarshaler.unmarshal(from: content),
                originalContent: content
            )
        )
        .padding()
    } header: {
        Text("Linear Correction")
            .font(.headline)
    }
    .frame(minWidth: 600, maxWidth: 600)
}
