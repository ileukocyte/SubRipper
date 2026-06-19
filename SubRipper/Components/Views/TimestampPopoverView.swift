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
        guard let _ = try? SrtMarshaler.parseTime(formatted: formatted) else {
            return false
        }

        guard SrtMarshaler.formatTime(timestamp) != formatted else {
            return false
        }

        return true
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
