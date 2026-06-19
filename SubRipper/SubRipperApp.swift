//
//  SubRipperApp.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import SwiftUI

@main
struct SubRipperApp: App {
    @State private var store = SubRipperStore()

    var body: some Scene {
        Window("SubRipper", id: "startup") {
            StartupView()
                .onAppear {
                    NSApp.centerWindow(id: "startup")
                }
                .containerBackground(.clear, for: .window)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 400)
        .defaultLaunchBehavior(.presented)
        .commands {
            FileCommands(store: store)
        }
        .environment(store)
        
        WindowGroup("SubRipper", id: "file", for: UUID.self) { $id in
            if let id, let file = store[id] {
                FileView(file: file)
                    .onAppear {
                        DispatchQueue.main.async {
                            NSApp.maximizeWindow(id: nil)
                        }
                    }
            }
        }
        .defaultPosition(.center)
        .environment(store)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
