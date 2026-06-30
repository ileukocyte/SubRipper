//
//  FocusedValuesExtensions.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import SwiftUI

extension FocusedValues {
    @Entry var currentFile: SRTFile?
    @Entry var entrySelection: Binding<Set<SRTEntry.ID>>?
    @Entry var showSubtitleInspector: Binding<Bool>?
    @Entry var showSubtitleOffsetSheet: Binding<Bool>?
    @Entry var showLinearCorrectionSheet: Binding<Bool>?
    @Entry var showSearchPanel: Binding<Bool>?
}
