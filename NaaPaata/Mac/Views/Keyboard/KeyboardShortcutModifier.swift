//
//  KeyboardShortcutModifier.swift
//  NaaPaataForMac
//

import SwiftUI
import AppKit

struct KeyboardShortcutModifier: ViewModifier {

    @ObservedObject var viewModel: MusicLibraryViewModel

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { installMonitor() }
            .onDisappear { removeMonitor() }
    }

    private func installMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        // Let text editing win — search field, playlist name sheet, etc.
        guard !isEditingText() else { return event }

        let relevantFlags = event.modifierFlags.intersection(
            [.command, .option, .control, .shift]
        )

        switch event.keyCode {
        case 49:                                   // Space
            guard relevantFlags.isEmpty else { return event }
            viewModel.togglePlayPause()
            return nil

        default:
            return event
        }
    }

    private func isEditingText() -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else {
            return false
        }
        return responder is NSTextView || responder is NSTextField
    }
}

extension View {
    func musicKeyboardShortcuts(for viewModel: MusicLibraryViewModel) -> some View {
        modifier(KeyboardShortcutModifier(viewModel: viewModel))
    }
}
