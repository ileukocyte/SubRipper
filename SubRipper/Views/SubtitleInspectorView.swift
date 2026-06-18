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
                TextEditor(text: $selectedEntry.content)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
            }

            Section(header: Text("Timing")) {
                Button {
                    startTimePopover.toggle()
                } label: {
                    LabeledContent("Start") {
                        Text(SrtMarshaler.formatTime(selectedEntry.startTime))
                            .font(.system(.body, design: .monospaced))
                    }
                    .background(.bar)
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
                    TimestampPopoverView(timestamp: $selectedEntry.startTime)
                }

                Button {
                    endTimePopover.toggle()
                } label: {
                    LabeledContent("End") {
                        Text(SrtMarshaler.formatTime(selectedEntry.endTime))
                            .font(.system(.body, design: .monospaced))
                    }
                    .background(.bar)
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
                    TimestampPopoverView(timestamp: $selectedEntry.endTime)
                }
            }
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var entry = SrtEntry(index: 2, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?")
    ZStack {}
        .inspector(isPresented: .constant(true)) {
            SubtitleInspectorView(selectedEntry: $entry)
        }
}
