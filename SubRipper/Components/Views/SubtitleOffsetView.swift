//
//  SubtitleOffsetView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/20/2026.
//

import SwiftUI

struct SubtitleOffsetView: View {
    static let formattedDefault = "00:00:00,000"

    var entries: [Binding<SrtEntry>]
    let shouldDismiss: Bool

    @Environment(\.dismiss) var dismiss

    @State private var timestamp: TimeInterval = 0
    @State private var formatted: String = Self.formattedDefault
    @State private var sign: FloatingPointSign = .plus

    var canSave: Bool {
        guard let _ = try? SrtMarshaler.timestampRegex.wholeMatch(in: formatted) else {
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

                    if let newTimestamp = try? SrtMarshaler.parseTime(formatted: formatted) {
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

                formatted = SrtMarshaler.formatTime(timestamp + offsetSeconds)
            } onDecrement: {
                let offsetSeconds = calculateOffset()

                formatted = SrtMarshaler.formatTime(max(0, timestamp - offsetSeconds))
            }
        }

        Divider()

        Button("Apply") {
            applyOffset()
        }
        .disabled(!canSave)
        .buttonBorderShape(.capsule)
        .buttonStyle(.borderedProminent)
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
        formatted = Self.formattedDefault

        if shouldDismiss {
            dismiss()
        }
    }
}

#Preview {
    @Previewable var entries: [Binding<SrtEntry>] = [.constant(SrtEntry(index: 2, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?"))]

    SubtitleOffsetView(entries: entries, shouldDismiss: false)
}
