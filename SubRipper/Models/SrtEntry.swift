//
//  SrtEntry.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/5/2026.
//

import Foundation

struct SrtEntry: Identifiable, Hashable {
    var id: Int
    var startTime: TimeInterval
    var endTime: TimeInterval
    var content: String
}
