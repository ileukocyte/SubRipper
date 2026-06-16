//
//  SubRipperApp.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct SubRipperApp: App {
    static let srtType = UTType(filenameExtension: "srt") ?? .item

    @State private var store = SubRipperStore()
    @State private var showFileImporter = false

    var body: some Scene {
        Window("SubRipper", id: "startup") {
            StartupView(showFileImporter: $showFileImporter)
                .onAppear {
                    NSApp.centerWindow(id: "startup")
                }
                .containerBackground(.clear, for: .window)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 400)
        .defaultLaunchBehavior(.presented)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Open...", systemImage: "arrow.up.right.square")
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        .environment(store)
        
        WindowGroup("File", id: "file", for: UUID.self) { $id in
            if let id, let file = store[id] {
                FileView(file: file, showFileImporter: $showFileImporter)
                    .onAppear {
                        NSApp.maximizeWindow(id: nil)
                    }
            }
        }
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Open...", systemImage: "arrow.up.right.square")
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        .environment(store)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
