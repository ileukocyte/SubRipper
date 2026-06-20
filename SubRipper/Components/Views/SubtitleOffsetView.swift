//
//  SubtitleOffsetView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/20/2026.
//

import SwiftUI

struct SubtitleOffsetView: View {
    static let formattedDefault = "00:00:00,000"

    @Binding var entry: SrtEntry

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
                formatted = SrtMarshaler.formatTime(timestamp + 1)
            } onDecrement: {
                formatted = SrtMarshaler.formatTime(max(0, timestamp - 1))
            }
        }

        Divider()

        HStack {
            Spacer()

            Button("Apply") {
                applyOffset()
            }
            .disabled(!canSave)
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    private func applyOffset() {
        switch sign {
        case .plus:
            entry.startTime += timestamp
            entry.endTime += timestamp
        case .minus:
            entry.startTime = max(0, entry.startTime - timestamp)
            entry.endTime = max(0, entry.endTime - timestamp)
        }

        timestamp = 0
        sign = .plus
        formatted = Self.formattedDefault
    }
}

#Preview {
    @Previewable @State var entry = SrtEntry(index: 2, startTime: 0.0, endTime: 121.0, content: "Why are you\nall dressed up?")

    SubtitleOffsetView(entry: $entry)
}
