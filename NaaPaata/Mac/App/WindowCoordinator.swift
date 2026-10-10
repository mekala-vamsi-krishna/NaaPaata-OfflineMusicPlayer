//
//  WindowCoordinator.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import AppKit
import SwiftUI
import AVFAudio

@MainActor
final class WindowCoordinator: NSObject {

    static let shared = WindowCoordinator()

    private weak var mainWindow: NSWindow?
    private var miniPlayerPanel: NSPanel?
    private var equalizerWindow: NSWindow?

    private weak var currentEqualizerEngine: EqualizerEngine?
    private var isAdjusting = false

    private override init() { super.init() }

    // MARK: - Registration

    func registerMainWindow(_ window: NSWindow) {
        mainWindow = window
    }

    // MARK: - Main window

    func hideMainWindow() {
        if mainWindow == nil {
            mainWindow = NSApp.windows.first {
                $0.identifier?.rawValue.contains("SwiftUI.WindowGroup") == true
            }
        }
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

    func clampMainWindow() {
        guard !isAdjusting, let window = mainWindow else { return }
        guard let screen = window.screen ?? NSScreen.main else { return }
        guard !window.styleMask.contains(.fullScreen) else { return }

        isAdjusting = true
        defer { isAdjusting = false }

        let visible = screen.visibleFrame
        var frame = window.frame

        if frame.width > visible.width { frame.size.width = visible.width }
        if frame.height > visible.height { frame.size.height = visible.height }

        frame.origin.x = max(visible.minX,
                             min(frame.origin.x, visible.maxX - frame.width))
        frame.origin.y = max(visible.minY,
                             min(frame.origin.y, visible.maxY - frame.height))

        guard frame != window.frame else { return }
        window.setFrame(frame, display: true, animate: false)
    }

    // MARK: - Mini Player — NSPanel, floats above other apps

    func showMiniPlayer(libraryViewModel: MusicLibraryViewModel) {
        if let panel = miniPlayerPanel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let root = MiniPlayerView(viewModel: libraryViewModel)
        let hosting = NSHostingController(rootView: root)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 380),
            styleMask: [.titled, .closable, .miniaturizable,
                        .fullSizeContentView, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hosting
        panel.title = "Mini Player"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false

        panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        panel.isReleasedWhenClosed = false
        panel.setFrameAutosaveName("")
        panel.center()
        panel.delegate = self

        miniPlayerPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    // MARK: - Equalizer — plain NSWindow, normal z-order

    func showEqualizer(
        equalizerViewModel: EqualizerViewModel,
        engine: EqualizerEngine,
        playerService: AudioPlayerService,
        store: StoreManager
    ) {
        // 1. Lazy attach on first open.
        if !engine.isAttached {
            let position = playerService.currentPosition
            let wasPlaying = playerService.isPlaying
            
            playerService.invalidateScheduledCompletion()

            do {
                try engine.attach(
                    to: playerService.audioEngine,
                    source: playerService.playerNode,
                    destination: playerService.audioEngine.mainMixerNode
                )
                equalizerViewModel.engine = engine
                equalizerViewModel.syncEngine()
            } catch {
                print("Equalizer attach failed:", error)
            }
            
            // Restore playback using the existing API.
            playerService.seek(toTime: position)
            if wasPlaying {
                playerService.play()
            }
        }

        // 2. Enable FFT publishing only while visible.
        engine.isVisible = true
        currentEqualizerEngine = engine

        // 3. Reuse existing window.
        if let window = equalizerWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 4. Build a fresh NSWindow — not NSPanel.
        let targetSize = preferredEqualizerSize()
        let root = EqualizerView()
            .environmentObject(equalizerViewModel)
            .environmentObject(engine)
            .environmentObject(store)
        
        let hosting = NSHostingController(rootView: root)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: targetSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hosting
        window.title = "Equalizer"
        window.minSize = NSSize(width: 1_020, height: 620)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("")
        window.delegate = self

        // Center on the current screen.
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.midX - targetSize.width / 2,
                y: visible.midY - targetSize.height / 2
            )
            window.setFrame(
                NSRect(origin: origin, size: targetSize),
                display: true,
                animate: false
            )
        }

        equalizerWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Preferred size

    private func preferredEqualizerSize() -> NSSize {
        guard let screen = NSScreen.main else {
            return NSSize(width: 1_200, height: 720)
        }
        let visible = screen.visibleFrame
        let width  = max(min(visible.width  - 80, 1_600), 1_020)
        let height = max(min(visible.height - 80, 1_000), 620)
        return NSSize(width: width, height: height)
    }
}

// MARK: - Panel / Window lifecycle

extension WindowCoordinator: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window === equalizerWindow {
            currentEqualizerEngine?.isVisible = false
            currentEqualizerEngine = nil
            equalizerWindow = nil
        }

        if window === miniPlayerPanel {
            miniPlayerPanel = nil
        }
    }
}
