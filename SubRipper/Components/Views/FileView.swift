//
//  FileView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct FileView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(SubRipperStore.self) private var store

    @Bindable var file: SrtFile

    @State private var showSubtitleInspector = true

    var body: some View {
        FileTableView(file: file, showSubtitleInspector: $showSubtitleInspector)
            .background { WindowMaximizer() }
            .background {
                ClosingWindowInterceptor {
                    let marshaled = SrtMarshaler.marshal(file.entries)

                    guard marshaled != file.originalContent else {
                        file.url.stopAccessingSecurityScopedResource()
                        store.remove(id: file.id)

                        if !store.hasOpenFiles {
                            openWindow(id: "startup")
                        }

                        return true
                    }

                    let alert = NSAlert()
                    alert.messageText = "Do you want to save the changes?"
                    alert.alertStyle = .warning

                    let (_, discard, _) = (
                        alert.addButton(withTitle: "Save"),
                        alert.addButton(withTitle: "Don't Save"),
                        alert.addButton(withTitle: "Cancel")
                    )
                    discard.hasDestructiveAction = true

                    switch alert.runModal() {
                    case .alertFirstButtonReturn:
                        do {
                            try store.export(file: file)
                        } catch {
                            Alerts.showDefaultErrorAlert(for: error)
                        }

                        fallthrough
                    case .alertSecondButtonReturn:
                        file.url.stopAccessingSecurityScopedResource()
                        store.remove(id: file.id)

                        if !store.hasOpenFiles {
                            openWindow(id: "startup")
                        }

                        return true
                    default:
                        return false
                    }
                }
            }
            .focusedSceneValue(\.currentFile, file)
            .focusedSceneValue(\.showSubtitleInspector, $showSubtitleInspector)
            .navigationTitle(file.url.lastPathComponent)
            .navigationDocument(file.url)
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        showSubtitleInspector.toggle()
                    } label: {
                        Label("Subtitle Inspector", systemImage: "sidebar.right")
                    }
                }
            }
    }
}

#Preview {
    let url = URL(fileURLWithPath: "A Heart in Winter (1992).srt")
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

    FileView(file: SrtFile(
        url: url,
        entries: try! SrtMarshaler.unmarshal(from: content),
        originalContent: content
    ))
    .environment(SubRipperStore())
}
