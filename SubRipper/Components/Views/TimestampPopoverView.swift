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

    @State private var formatted: String

    var heading: String?

    init(timestamp: Binding<TimeInterval>, heading: String? = nil) {
        self._timestamp = timestamp
        self._formatted = State(initialValue: SrtMarshaler.formatTime(timestamp.wrappedValue))
        self.heading = heading
    }

    var canSave: Bool {
        // checks for regex matching as well
        guard let formatted = addMissingLeadingZeros(to: formatted) else {
            return false
        }

        return SrtMarshaler.formatTime(timestamp) != formatted
    }

    var body: some View {
        VStack(spacing: 15) {
            Section {
                TextField("Timestamp", text: $formatted)
                    .frame(width: 100)
                    .onChange(of: formatted) { _, newValue in
                        formatted = newValue.filter {
                            $0.isNumber || $0 == ":" || $0 == ","
                        }
                    }
                    .onSubmit {
                        if let time = try? SrtMarshaler.parseTime(formatted: formatted) {
                            timestamp = time
                            dismiss()
                        }
                    }

                Button("Save") {
                    if let time = try? SrtMarshaler.parseTime(formatted: formatted) {
                        timestamp = time
                        dismiss()
                    }
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

    private func addMissingLeadingZeros(to string: String) -> String? {
        guard let match = try? SrtMarshaler.timestampRegex.wholeMatch(in: string) else {
            return nil
        }

        let hours = match.hours.count == 1 ? "0\(match.hours)" : match.hours
        let minutes = match.minutes.count == 1 ? "0\(match.minutes)" : match.minutes
        let seconds = match.seconds.count == 1 ? "0\(match.seconds)" : match.seconds

        return "\(hours):\(minutes):\(seconds),\(match.ms)"
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
