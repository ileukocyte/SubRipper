//
//  TimestampPopoverView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/18/2026.
//

import SwiftUI

struct TimestampPopoverView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var timestamp: TimeInterval

    @State private var localTimestamp: TimeInterval
    @State private var formatted: String

    var heading: String?

    init(timestamp: Binding<TimeInterval>, heading: String? = nil) {
        self._timestamp = timestamp
        self._localTimestamp = State(initialValue: timestamp.wrappedValue)
        self._formatted = State(initialValue: SrtMarshaler.formatTime(timestamp.wrappedValue))
        self.heading = heading
    }

    private var canSave: Bool {
        guard let newTimestamp = try? SrtMarshaler.parseTime(formatted: formatted) else {
            return false
        }

        return timestamp != newTimestamp
    }

    var body: some View {
        VStack(spacing: 15) {
            Section {
                HStack {
                    TextField("Timestamp", text: $formatted)
                        .frame(width: 100)
                        .onChange(of: formatted) { _, newValue in
                            formatted = newValue.filter {
                                $0.isNumber || $0 == ":" || $0 == ","
                            }

                            if let newTimestamp = try? SrtMarshaler.parseTime(formatted: formatted) {
                                localTimestamp = newTimestamp
                            }
                        }
                        .onSubmit {
                            if canSave {
                                timestamp = localTimestamp
                            }

                            dismiss()
                        }

                    Stepper {
                        
                    } onIncrement: {
                        let offsetSeconds = calculateOffset()

                        formatted = SrtMarshaler.formatTime(localTimestamp + offsetSeconds)
                    } onDecrement: {
                        let offsetSeconds = calculateOffset()

                        formatted = SrtMarshaler.formatTime(max(0, localTimestamp - offsetSeconds))
                    }
                }
                .frame(maxWidth: .infinity)

                Button("Save") {
                    timestamp = localTimestamp
                    dismiss()
                }
                .disabled(!canSave)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            } header: {
                if let heading {
                    Text(heading)
                        .font(.headline)
                }
            }
        }
        .padding()
    }

    private func calculateOffset() -> TimeInterval {
        if Keys.allModifiersPressed([.option, .shift]) {
            60
        } else if Keys.allModifiersPressed([.shift]) {
            30
        } else if Keys.allModifiersPressed([.option]) {
            15
        } else {
            1
        }
    }
}

#Preview {
    @Previewable @State var timestamp: TimeInterval = 69.123
    @Previewable @State var isPresented = true

    ZStack {
        Button("Test") {
            isPresented.toggle()
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .popover(isPresented: $isPresented) {
            TimestampPopoverView(timestamp: $timestamp, heading: "End Time")
        }
    }
    .padding(20)
}
