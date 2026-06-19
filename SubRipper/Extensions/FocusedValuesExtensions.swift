//
//  FocusedValuesExtensions.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import SwiftUI

extension FocusedValues {
    @Entry var currentFile: SrtFile? = nil
    @Entry var showSubtitleInspector: Binding<Bool>? = nil
}
