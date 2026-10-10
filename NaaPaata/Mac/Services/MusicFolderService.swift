//
//  MusicFolderService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

enum MusicFolderError: LocalizedError {
    case creationFailed(URL, Error)

    var errorDescription: String? {
        switch self {
        case .creationFailed(let url, let error):
            return "Failed to create \(url.path): \(error.localizedDescription)"
        }
    }
}

final class MusicFolderService {

    static let folderName = "Naa Paata"

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    var naaPaataFolderURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Music", isDirectory: true)
            .appendingPathComponent(Self.folderName, isDirectory: true)
    }

    @discardableResult
    func ensureNaaPaataFolderExists() throws -> URL {
        let folder = naaPaataFolderURL

        if !fileManager.fileExists(atPath: folder.path) {
            do {
                try fileManager.createDirectory(
                    at: folder,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw MusicFolderError.creationFailed(folder, error)
            }
        }

        setFolderIcon(on: folder)
        return folder
    }

    // MARK: - Folder icon

    /// Builds a composite icon — the system folder shape with the app icon
    /// overlaid in its centre — and applies it to `folder`.
    private func setFolderIcon(on folder: URL) {
        guard let appIcon = NSApp.applicationIconImage else { return }
        let folderIcon = NSWorkspace.shared.icon(for: .folder)

        let composed = makeComposedIcon(
            folder: folderIcon,
            app: appIcon,
            size: 512
        )

        let success = NSWorkspace.shared.setIcon(
            composed,
            forFile: folder.path,
            options: []
        )

        if !success {
            print("⚠️ Could not set folder icon at \(folder.path)")
        }
    }

    /// Composites the folder icon as a base and the app icon on top.
    ///
    /// - `folder`  — the base image (macOS folder shape)
    /// - `app`     — the overlay image (the app's icon)
    /// - `size`    — canvas size in points; 512 matches modern macOS icons
    private func makeComposedIcon(
        folder: NSImage,
        app: NSImage,
        size: CGFloat
    ) -> NSImage {
        let canvas = NSSize(width: size, height: size)

        return NSImage(size: canvas, flipped: false) { rect in
            // MARK: Base — system folder
            folder.draw(
                in: rect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )

            // MARK: Overlay — app icon, centred inside the folder body
            let appSide = rect.width * 0.55
            let appOrigin = NSPoint(
                x: rect.midX - appSide / 2,
                y: rect.minY + rect.height * 0.18
            )

            app.draw(
                in: NSRect(origin: appOrigin, size: NSSize(width: appSide, height: appSide)),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )

            return true
        }
    }
}
