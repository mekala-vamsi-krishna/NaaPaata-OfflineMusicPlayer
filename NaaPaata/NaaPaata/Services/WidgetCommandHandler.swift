//
//  WidgetCommandHandler.swift
//  NaaPaata
//

import Foundation
import CoreFoundation

/// Observes Darwin notifications posted by the widget and forwards
/// the command to the shared `MusicLibraryViewModel`.
@MainActor
final class WidgetCommandHandler {

    static let shared = WidgetCommandHandler()

    /// Set once at app launch. `weak` — the app owns the view model.
    weak var libraryViewModel: MusicLibraryViewModel?

    private var observerToken: UnsafeMutableRawPointer?
    private var lastProcessedCommandID: String?

    private init() {}

    // MARK: - Lifecycle

    func start() {
        guard observerToken == nil else { return }

        let unmanaged = Unmanaged.passUnretained(self)
        observerToken = UnsafeMutableRawPointer(unmanaged.toOpaque())

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observerToken,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let handler = Unmanaged<WidgetCommandHandler>
                    .fromOpaque(observer)
                    .takeUnretainedValue()

                Task { @MainActor in
                    handler.processLatestCommand()
                }
            },
            SharedDataManager.widgetCommandNotification as CFString,
            nil,
            .deliverImmediately
        )

        // Handle a command that may have arrived before the observer
        // was registered (e.g. cold launch from a widget tap).
        processLatestCommand()
    }

    func stop() {
        guard let observerToken else { return }

        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observerToken,
            CFNotificationName(SharedDataManager.widgetCommandNotification as CFString),
            nil
        )
        self.observerToken = nil
    }

    // MARK: - Command processing

    private func processLatestCommand() {
        guard let envelope = SharedDataManager.shared.readCommand() else { return }
        guard envelope.id != lastProcessedCommandID else { return }

        lastProcessedCommandID = envelope.id

        // Defer one runloop tick so the app has finished launching.
        Task { @MainActor in
            guard let viewModel = libraryViewModel else { return }

            switch envelope.command {
            case .playPause: viewModel.togglePlayPause()
            case .next:      viewModel.playNext()
            case .previous:  viewModel.playPrevious()
            }

            SharedDataManager.shared.clearCommand()
        }
    }
}
