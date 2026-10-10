//
//  MiniPlayerWindowConfigurator.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI
import AppKit

struct MiniPlayerWindowConfigurator: NSViewRepresentable {

    @Binding var isHovering: Bool

    private let contentSize = NSSize(width: 380, height: 380)
    private let cornerRadius: CGFloat = 14

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setFrameSize(.zero)
        configureWhenReady(view, coordinator: context.coordinator, attempt: 0)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        setTrafficLightsAlpha(isHovering ? 1 : 0, on: window, animated: true)
    }

    // MARK: - Delayed configuration

    private func configureWhenReady(
        _ view: NSView,
        coordinator: Coordinator,
        attempt: Int
    ) {
        guard let window = view.window else {
            if attempt < 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    configureWhenReady(view, coordinator: coordinator, attempt: attempt + 1)
                }
            }
            return
        }
        configure(window, coordinator: coordinator)
    }

    // MARK: - Configuration

    private func configure(_ window: NSWindow, coordinator: Coordinator) {
        // Chrome
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none

        // Opaque window with black backing.
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = true

        // Round the content view's layer to match the SwiftUI clip.
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = cornerRadius
            contentView.layer?.masksToBounds = true
            contentView.layer?.backgroundColor = NSColor.black.cgColor
        }

        // Behaviour
        window.isMovableByWindowBackground = true
        window.level = .normal
        window.collectionBehavior.insert(.fullScreenAuxiliary)

        // Force content size
        window.contentMinSize = contentSize
        window.contentMaxSize = contentSize
        window.setContentSize(contentSize)

        // Hide zoom permanently
        window.standardWindowButton(.zoomButton)?.isHidden = true

        // Traffic lights hidden by default
        setTrafficLightsAlpha(0, on: window, animated: false)

        // Key on open so first click works
        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        // Restore main window on close
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(Coordinator.windowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    private func setTrafficLightsAlpha(
        _ alpha: CGFloat,
        on window: NSWindow,
        animated: Bool
    ) {
        let buttons = [
            window.standardWindowButton(.closeButton),
            window.standardWindowButton(.miniaturizeButton)
        ].compactMap { $0 }

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.18
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                for button in buttons {
                    button.animator().alphaValue = alpha
                }
            }
        } else {
            for button in buttons {
                button.alphaValue = alpha
            }
        }
    }

    final class Coordinator: NSObject {
        @objc func windowWillClose(_ notification: Notification) {
            Task { @MainActor in
                WindowCoordinator.shared.showMainWindow()
            }
        }
    }
}
