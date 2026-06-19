//
//  SettingsView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/16/2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                ZStack {
                    
                }
            }
        }
        .scenePadding()
        .frame(maxWidth: 350, minHeight: 100)
    }
}

#Preview {
    SettingsView()
}
