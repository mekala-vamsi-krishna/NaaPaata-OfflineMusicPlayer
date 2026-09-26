//
//  WindowConfigurator.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI
import AppKit

struct WindowConfigurator: NSViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setFrameSize(.zero)
        configureWhenReady(view, coordinator: context.coordinator)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func configureWhenReady(_ view: NSView, coordinator: Coordinator) {
        guard let window = view.window else {
            DispatchQueue.main.async {
                configureWhenReady(view, coordinator: coordinator)
            }
            return
        }
        configure(window, coordinator: coordinator)
    }

    private func configure(_ window: NSWindow, coordinator: Coordinator) {
        Task { @MainActor in
            WindowCoordinator.shared.registerMainWindow(window)
        }

        let nc = NotificationCenter.default

        coordinator.observers.append(
            nc.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    WindowCoordinator.shared.clampMainWindow()
                }
            }
        )
        coordinator.observers.append(
            nc.addObserver(
                forName: NSWindow.didEndLiveResizeNotification,
                object: window,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    WindowCoordinator.shared.clampMainWindow()
                }
            }
        )
        coordinator.observers.append(
            nc.addObserver(
                forName: NSWindow.didChangeScreenNotification,
                object: window,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    WindowCoordinator.shared.fitMainWindowToWidth()
                }
            }
        )

        // Launch fit — runs four times to beat macOS's frame restore.
        Task { @MainActor in
            WindowCoordinator.shared.fitMainWindowToWidth()
            try? await Task.sleep(nanoseconds: 100_000_000)
            WindowCoordinator.shared.fitMainWindowToWidth()
            try? await Task.sleep(nanoseconds: 400_000_000)
            WindowCoordinator.shared.fitMainWindowToWidth()
            try? await Task.sleep(nanoseconds: 800_000_000)
            WindowCoordinator.shared.fitMainWindowToWidth()
        }
    }

    final class Coordinator {
        var observers: [NSObjectProtocol] = []

        deinit {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
