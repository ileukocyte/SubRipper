//
//  StartupView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct StartupView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(SubRipperStore.self) private var store

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Group {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.secondary)

                    Text("SubRipper")
                        .font(.largeTitle.weight(.bold))
                }

                Group {
                    Text("Open an .srt file to get started")
                        .foregroundStyle(.secondary)
                        
                    Button("Open", systemImage: "arrow.up.forward") {
                        FilePanels.openNSOpenPanel { urls, encoding in
                            var isStartupOpen = true

                            for url in urls {
                                let accessed = url.startAccessingSecurityScopedResource()

                                do {
                                    let file = try store.load(url: url, encoding: encoding)

                                    if isStartupOpen {
                                        NSApp.closeWindow(id: "startup")
                                        isStartupOpen = false
                                    }

                                    openWindow(id: "file", value: file.id)
                                } catch {
                                    if accessed {
                                        url.stopAccessingSecurityScopedResource()
                                    }

                                    Alerts.showDefaultErrorAlert(for: error)
                                }
                            }
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .controlSize(.large)

                    Text("or drag a file anywhere into this window")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .navigationTitle("")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .windowMinimizeBehavior(.disabled)
        .windowResizeBehavior(.disabled)
        .background(.ultraThinMaterial)
        .dropDestination(for: URL.self) { items, _ in
            let urls = items.filter { $0.pathExtension.lowercased() == "srt" }

            if urls.isEmpty {
                return
            }

            var isStartupOpen = true

            for url in urls {
                let accessed = url.startAccessingSecurityScopedResource()
                
                do {
                    let file = try store.load(url: url)

                    if isStartupOpen {
                        NSApp.closeWindow(id: "startup")
                        isStartupOpen = false
                    }

                    openWindow(id: "file", value: file.id)
                } catch {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    Alerts.showDefaultErrorAlert(for: error)
                }
            }
        }
    }
}

#Preview {
    StartupView()
        .navigationTitle("")
        .containerBackground(.clear, for: .window)
        .environment(SubRipperStore())
}
