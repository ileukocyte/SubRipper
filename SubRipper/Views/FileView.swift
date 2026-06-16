//
//  FileView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct FileView: View {
    let file: SrtFile

    @Environment(\.openWindow) private var openWindow
    @Environment(SubRipperStore.self) private var store

    @Binding var showFileImporter: Bool

    @State private var selection: SrtEntry.ID?
    @State private var showError = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            FileTableView(entries: file.entries, selection: $selection)
        }
        .onDisappear {
            file.url.stopAccessingSecurityScopedResource()
            store.remove(id: file.id)

            if !store.hasOpenFiles {
                openWindow(id: "startup")
            }
        }
        .navigationTitle(file.url.lastPathComponent)
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [SubRipperApp.srtType]
        ) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()

                do {
                    let file = try store.load(url: url)

                    openWindow(id: "file", value: file.id)
                } catch {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }

                    errorMessage = error.localizedDescription
                    showError = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .close) {
                
            }.keyboardShortcut(.defaultAction)
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

#Preview {
    let url = URL(fileURLWithPath: "~/Movies/movies/watch later/A Heart in Winter (1992).srt")
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

    FileView(file: SrtFile(url: url, entries: try! SrtMarshaler.unmarshal(content)), showFileImporter: .constant(false))
        .environment(SubRipperStore())
}
