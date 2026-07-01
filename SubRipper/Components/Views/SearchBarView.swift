//
//  SearchBarView.swift
//  SubRipper
//
//  Created by Alexander Oksanich on 6/30/2026.
//

import SwiftUI

struct SearchBarView: NSViewRepresentable {
    @Binding var query: String
    @Binding var matchCase: Bool

    var onEscape: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?

    func makeNSView(context: Context) -> NSSearchField {
        let view = NSSearchField()
        view.delegate = context.coordinator
        view.searchMenuTemplate = context.coordinator.makeSearchMenu()

        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }

        return view
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.parent = self

        guard nsView.stringValue != query else {
            return
        }

        nsView.stringValue = query
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchBarView

        init(parent: SearchBarView) {
            self.parent = parent
        }

        func makeSearchMenu() -> NSMenu {
            let menu = NSMenu()

            let matchCaseItem = NSMenuItem(
                title: "Match Case",
                action: #selector(toggleMatchCase(_:)),
                keyEquivalent: ""
            )
            matchCaseItem.image = NSImage(systemSymbolName: "textformat.alt", accessibilityDescription: matchCaseItem.title)
            matchCaseItem.target = self
            matchCaseItem.state = parent.matchCase ? .on : .off
            menu.addItem(matchCaseItem)

            return menu
        }

        @objc func toggleMatchCase(_ sender: NSMenuItem) {
            parent.matchCase.toggle()
            sender.state = parent.matchCase ? .on : .off
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSSearchField else {
                return
            }

            parent.query = view.stringValue
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
                if NSEvent.modifierFlags.contains(.shift) {
                    parent.onUpArrow?()
                } else {
                    parent.onDownArrow?()
                }

                return true
            default:
                return false
            }
        }
    }
}

#Preview {
    @Previewable @State var query = "test"
    @Previewable @State var matchCase = false

    Form {
        SearchBarView(
            query: $query,
            matchCase: $matchCase
        )
        .padding()
    }
}
