//
//  NotchWindowController.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/22/26.
//

import AppKit
import SwiftUI

/// An NSPanel that can appear above the menu bar without activating the app
/// or stealing key focus from whatever the user is doing.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class NotchWindowController {

    static let shared = NotchWindowController()

    private var panel: NotchPanel?

    private init() {}

    var isShowing: Bool { panel != nil }

    // MARK: - Show / hide

    func show(viewModel: MusicLibraryViewModel) {
        guard panel == nil else { return }
        guard let geometry = NotchGeometry.detect() else { return }

        let size = NotchMediaView.windowSize

        // Anchor the top of the panel flush with the top of the screen.
        let origin = NSPoint(
            x: geometry.centerX - size.width / 2,
            y: geometry.topEdgeY - size.height
        )

        let panel = NotchPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1
        )

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        let host = NSHostingView(
            rootView: NotchMediaView(
                viewModel: viewModel,
                geometry: geometry
            )
        )
        host.frame = NSRect(origin: .zero, size: size)
        panel.contentView = host

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }
}
