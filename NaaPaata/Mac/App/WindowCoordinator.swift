//
//  WindowCoordinator.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import AppKit

@MainActor
final class WindowCoordinator {

    static let shared = WindowCoordinator()

    private weak var mainWindow: NSWindow?
    private var isAdjusting = false

    private init() {}

    // MARK: - Registration

    func registerMainWindow(_ window: NSWindow) {
        mainWindow = window
    }

    // MARK: - Main window transitions

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }

    func showMainWindow() {
        if mainWindow == nil {
            mainWindow = NSApp.windows.first {
                $0.identifier?.rawValue.contains("SwiftUI.WindowGroup") == true
            }
        }
        guard let window = mainWindow else { return }

        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        window.makeKeyAndOrderFront(nil)
        clampMainWindow()
    }

    // MARK: - Fill the visible frame

    func fitMainWindowToWidth() {
        guard !isAdjusting, let window = mainWindow else { return }
        guard let screen = window.screen ?? NSScreen.main else { return }
        guard !window.styleMask.contains(.fullScreen) else { return }

        isAdjusting = true
        defer { isAdjusting = false }

        let visible = screen.visibleFrame
        guard window.frame != visible else { return }
        window.setFrame(visible, display: true, animate: false)
    }

    // MARK: - Clamp inside visible area

    func clampMainWindow() {
        guard !isAdjusting, let window = mainWindow else { return }
        guard let screen = window.screen ?? NSScreen.main else { return }
        guard !window.styleMask.contains(.fullScreen) else { return }

        isAdjusting = true
        defer { isAdjusting = false }

        let visible = screen.visibleFrame
        var frame = window.frame

        if frame.width > visible.width {
            frame.size.width = visible.width
        }
        if frame.height > visible.height {
            frame.size.height = visible.height
        }

        frame.origin.x = max(
            visible.minX,
            min(frame.origin.x, visible.maxX - frame.width)
        )
        frame.origin.y = max(
            visible.minY,
            min(frame.origin.y, visible.maxY - frame.height)
        )

        guard frame != window.frame else { return }
        window.setFrame(frame, display: true, animate: false)
    }
}

enum WindowID {
    static let miniPlayer = "miniPlayer"
}
