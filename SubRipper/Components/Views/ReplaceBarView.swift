//
//  ReplaceBarView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 7/2/2026.
//

import SwiftUI

struct ReplaceBarView: NSViewRepresentable {
    @Binding var replacement: String

    var onEscape: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onEnter: (() -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let view = NSTextField()
        view.delegate = context.coordinator
        view.bezelStyle = .squareBezel
        view.placeholderString = "Replace"

        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }

        return view
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self

        guard nsView.stringValue != replacement else {
            return
        }

        nsView.stringValue = replacement
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ReplaceBarView

        init(parent: ReplaceBarView) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextField else {
                return
            }

            parent.replacement = view.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onEscape?()

                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.onUpArrow?()

                return true
            case #selector(NSResponder.moveDown(_:)):
                parent.onDownArrow?()

                return true
            case #selector(NSResponder.insertNewline(_:)):
                parent.onEnter?()

                return true
            default:
                return false
            }
        }
    }
}

#Preview {
    @Previewable @State var replacement = "test"

    Form {
        ReplaceBarView(replacement: $replacement)
            .padding()
    }
}
