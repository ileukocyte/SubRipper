//
//  SubtitleOffsetView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/20/2026.
//

import SwiftUI

struct SubtitleOffsetView: View {
    var entries: [Binding<SRTEntry>]
    let shouldDismiss: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var timestamp: TimeInterval = 0
    @State private var formatted: String = SRTMarshaler.defaultFormattedTimestamp
    @State private var sign: FloatingPointSign = .plus

    private var canSave: Bool {
        guard let _ = try? SRTMarshaler.timestampRegex.wholeMatch(in: formatted) else {
            return false
        }

        return timestamp != 0
    }

    var body: some View {
        HStack {
            Picker("", selection: $sign) {
                Text("+").tag(FloatingPointSign.plus)
                Text("-").tag(FloatingPointSign.minus)
            }
            .pickerStyle(.segmented)

            Spacer()

            TextField("", text: $formatted)
                .frame(width: 100)
                .onChange(of: formatted) { _, newValue in
                    formatted = newValue.filter {
                        $0.isNumber || $0 == ":" || $0 == ","
                    }

                    if let newTimestamp = try? SRTMarshaler.parseTime(formatted: formatted) {
                        timestamp = newTimestamp
                    }
                }
                .onSubmit {
                    guard canSave else { return }

                    applyOffset()
                }

            Stepper {
                
            } onIncrement: {
                let offsetSeconds = calculateOffset()

                formatted = SRTMarshaler.formatTime(timestamp + offsetSeconds)
            } onDecrement: {
                let offsetSeconds = calculateOffset()

                formatted = SRTMarshaler.formatTime(max(0, timestamp - offsetSeconds))
            }
        }

        Divider()

        HStack {
            if shouldDismiss {
                Button("Cancel") {
                    dismiss()
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
            }

            Button("Apply") {
                applyOffset()
            }
            .disabled(!canSave)
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
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

    private func applyOffset() {
        for entry in entries {
            switch sign {
            case .plus:
                entry.wrappedValue.startTime += timestamp
                entry.wrappedValue.endTime += timestamp
            case .minus:
                entry.wrappedValue.startTime = max(0, entry.wrappedValue.startTime - timestamp)
                entry.wrappedValue.endTime = max(0, entry.wrappedValue.endTime - timestamp)
            }
        }

        timestamp = 0
        sign = .plus
        formatted = SRTMarshaler.defaultFormattedTimestamp

        if shouldDismiss {
            dismiss()
        }
    }
}

#Preview {
    @Previewable var entries: [Binding<SRTEntry>] = [
        .constant(SRTEntry(index: 2, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?"))
    ]

    SubtitleOffsetView(entries: entries, shouldDismiss: false)
}
