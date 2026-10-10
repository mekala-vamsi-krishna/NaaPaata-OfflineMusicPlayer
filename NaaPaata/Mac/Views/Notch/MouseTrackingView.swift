//
//  MouseTrackingView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/22/26.
//

import SwiftUI
import AppKit

/// Reliable hover tracking using NSTrackingArea.
///
/// SwiftUI's `.onHover` flickers when views overlay the tracking target.
/// NSTrackingArea tracks cursor position by rect containment — overlay
/// views have no effect on it. The view's `hitTest` returns nil, so
/// clicks pass through to whatever sits beneath.
struct MouseTrackingView: NSViewRepresentable {

    let onHover: (Bool) -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onHover = onHover
        view.addTrackingArea(
            NSTrackingArea(
                rect: .zero,
                options: [
                    .mouseEnteredAndExited,
                    .activeAlways,
                    .inVisibleRect
                ],
                owner: view,
                userInfo: nil
            )
        )
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        nsView.onHover = onHover
    }

    final class TrackingView: NSView {

        var onHover: ((Bool) -> Void)?

        override func mouseEntered(with event: NSEvent) {
            onHover?(true)
        }

        override func mouseExited(with event: NSEvent) {
            onHover?(false)
        }

        /// Return nil so all clicks pass through to underlying views
        /// (the play/prev/next buttons, in our case).
        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}
