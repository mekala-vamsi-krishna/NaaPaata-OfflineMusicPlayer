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
    case noFolderSelected
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .noFolderSelected:
            return "No music folder selected. Please choose a folder."
        case .accessDenied:
            return "Could not access the selected folder. Please select it again."
        }
    }
}

final class MusicFolderService {

    private let bookmarkKey = "NaaPaataLibraryBookmark"

    // MARK: - Folder Selection

    /// Prompts the user to pick a folder using async/await to prevent UI blocking.
    @MainActor
    func promptForFolderSelection() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select or create a folder for your Naa Paata music library."
        panel.prompt = "Select Folder"

        // Use the async version of begin() instead of runModal()
        let response = await panel.begin()
        
        guard response == .OK, let url = panel.url else {
            return nil
        }

        do {
            try saveBookmark(for: url)
            setFolderIcon(on: url)
            return url
        } catch {
            print("⚠️ Failed to save bookmark: \(error)")
            return nil
        }
    }

    // MARK: - Bookmarks

    func resolveBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                try? saveBookmark(for: url)
            }
            return url
        } catch {
            print("⚠️ Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    private func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }
    
    func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    // MARK: - Folder icon
    private func setFolderIcon(on folder: URL) {
        guard let appIcon = NSApp.applicationIconImage else { return }
        let folderIcon = NSWorkspace.shared.icon(for: .folder)

        let composed = makeComposedIcon(folder: folderIcon, app: appIcon, size: 512)
        let success = NSWorkspace.shared.setIcon(composed, forFile: folder.path, options: [])
        
        if !success {
            print("⚠️ Could not set folder icon at \(folder.path)")
        }
    }

    private func makeComposedIcon(folder: NSImage, app: NSImage, size: CGFloat) -> NSImage {
        let canvas = NSSize(width: size, height: size)
        return NSImage(size: canvas, flipped: false) { rect in
            folder.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            
            let appSide = rect.width * 0.55
            let appOrigin = NSPoint(x: rect.midX - appSide / 2, y: rect.minY + rect.height * 0.18)
            app.draw(in: NSRect(origin: appOrigin, size: NSSize(width: appSide, height: appSide)), from: .zero, operation: .sourceOver, fraction: 1.0)
            return true
        }
    }
}
