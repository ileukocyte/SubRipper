//
//  FileTableView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct FileTableView: View {
    let entries: [SrtEntry]

    @Binding var selection: SrtEntry.ID?
    @State private var showTestAlert = false

    var body: some View {
        Table(of: SrtEntry.self, selection: $selection) {
            TableColumn("Start") {
                Text(SrtMarshaler.formatTime($0.startTime))
            }
            .width(125)

            TableColumn("End") {
                Text(SrtMarshaler.formatTime($0.endTime))
            }
            .width(125)

            TableColumn("Subtitle", value: \.content)
        } rows: {
            ForEach(entries) { entry in
                TableRow(entry)
                    .contextMenu {
                        Button {
                            showTestAlert = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .alert("test content alert", isPresented: $showTestAlert) {
            Button("OK", role: .confirm) {
                
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            if let selection, let entry = entries.first(where: { $0.id == selection }) {
                Text(entry.content)
            } else {
                Text("N/A")
            }
        }
    }
}

#Preview {
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

    FileTableView(entries: try! SrtMarshaler.unmarshal(content), selection: .constant(nil))
}
