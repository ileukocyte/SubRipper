//
//  SubRipperErrors.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/19/2026.
//

import Foundation

enum SrtParseError: LocalizedError {
    case invalidIndex(String)
    case invalidTimeComponent(String)

    var errorDescription: String? {
        switch self {
        case .invalidIndex(let index):
            return "Invalid subtitle index: \(index)"
        case .invalidTimeComponent(let component):
            return "Invalid timestamp format: \(component)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        default:
            return "Please check the format of the .srt file."
        }
    }
}
