//
//  SubtitleInspectorView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct SubtitleInspectorView: View {
    @Binding var selectedEntry: SrtEntry

    @State private var startTimePopover = false
    @State private var endTimePopover = false

    var body: some View {
        Form {
            Section(header: Text("Subtitle")) {
                SubtitleTextEditorView(content: $selectedEntry.content)
                    .id(selectedEntry.id)
            }

            Section(header: Text("Timing")) {
                Button {
                    startTimePopover.toggle()
                } label: {
                    LabeledContent("Start") {
                        Text(SrtMarshaler.formatTime(selectedEntry.startTime))
                            .font(.system(.body, design: .monospaced))
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
                    TimestampPopoverView(timestamp: $selectedEntry.startTime, heading: "Start Time")
                        .id(selectedEntry.id)
                }

                Button {
                    endTimePopover.toggle()
                } label: {
                    LabeledContent("End") {
                        Text(SrtMarshaler.formatTime(selectedEntry.endTime))
                            .font(.system(.body, design: .monospaced))
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
                    TimestampPopoverView(timestamp: $selectedEntry.endTime, heading: "End Time")
                        .id(selectedEntry.id)
                }
            }
        }
        .padding(10)
    }
}

#Preview {
    @Previewable @State var entry = SrtEntry(index: 2, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?")
    ZStack {}
        .inspector(isPresented: .constant(true)) {
            SubtitleInspectorView(selectedEntry: $entry)
        }
}
