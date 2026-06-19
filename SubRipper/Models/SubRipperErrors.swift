//
//  SubRipperErrors.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import Foundation

enum SrtParseError: Error {
    case invalidIndex(String)
    case invalidTimeComponent(String)
}

enum SubRipperError: Error {
    case invalidUuid(UUID)
}
