//
//  SubtitleInspectorView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/17/2026.
//

import SwiftUI

struct SubtitleInspectorView: View {
    var entries: [Binding<SrtEntry>]
    var selectAll: () -> Void
    var deselect: () -> Void

    @State private var startTimePopover = false
    @State private var endTimePopover = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()

                    VStack {
                        Text("^[\(entries.count) subtitle](inflect: true) selected")

                        HStack {
                            Button("Select All") {
                                selectAll()
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)

                            Button("Deselect") {
                                deselect()
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                    }

                    Spacer()
                }
            }

            if entries.count == 1, let entry = entries.first {
                Section(header: Text("Subtitle")) {
                    SubtitleTextEditorView(content: entry.content)
                        .id(entry.wrappedValue.id)
                }
                
                Section(header: Text("Timing")) {
                    Button {
                        startTimePopover.toggle()
                    } label: {
                        LabeledContent("Start") {
                            Text(SrtMarshaler.formatTime(entry.wrappedValue.startTime))
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
                        TimestampPopoverView(timestamp: entry.startTime, heading: "Start Time")
                            .id(entry.wrappedValue.id)
                    }
                    
                    Button {
                        endTimePopover.toggle()
                    } label: {
                        LabeledContent("End") {
                            Text(SrtMarshaler.formatTime(entry.wrappedValue.endTime))
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
                        TimestampPopoverView(timestamp: entry.endTime, heading: "End Time")
                            .id(entry.wrappedValue.id)
                    }
                }
            }

            Section(header: Text("Offset")) {
                LabeledContent {
                    SubtitleOffsetView(entries: entries)
                } label: {
                    
                }
            }
        }
        .padding(10)
    }
}

#Preview {
    @Previewable @State var entries: [Binding<SrtEntry>] = [.constant(SrtEntry(index: 2, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?"))]

    ZStack {
        
    }
    .inspector(isPresented: .constant(true)) {
        SubtitleInspectorView(entries: entries) {

        } deselect: {
            entries.removeAll()
        }
    }
}
