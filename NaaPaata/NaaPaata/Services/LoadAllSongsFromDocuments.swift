//
//  LoadAllSongsFromDocuments.swift
//  NaaPaata
//
//  Created by User on 05/10/25.
//

import Foundation

class LoadAllSongsFromDocuments {
    private let audioExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aiff", "caf",
        "flac", "ogg", "opus", "wma", "alac"
    ]
    
    // MARK: - loadSongsFromDocuments
    func loadSongsFromDocuments() -> [URL] {
        return loadAllAudioFilesWithRelativePaths().map { $0.url }
    }
    
    // MARK: - loadAllAudioFilesWithRelativePaths
    func loadAllAudioFilesWithRelativePaths() -> [(url: URL, relativePath: String)] {
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        print("🗂️ Naa Paata Documents folder: \(docsURL.path)")
        createPlaceholderFileIfNeeded(in: docsURL)
        
        guard let enumerator = fileManager.enumerator(
            at: docsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }
        
        let docsPath = docsURL.path + "/"
        var results: [(url: URL, relativePath: String)] = []
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else { continue }
            let ext = fileURL.pathExtension.lowercased()
            if audioExtensions.contains(ext) {
                let relPath = fileURL.path.replacingOccurrences(of: docsPath, with: "")
                results.append((fileURL, relPath))
            }
        }
        results.sort { $0.relativePath < $1.relativePath }
        print("🗂️ Found \(results.count) audio files.")
        return results
    }
    
    // MARK: - createPlaceholderFileIfNeeded
    private func createPlaceholderFileIfNeeded(in directory: URL) {
        let fileManager = FileManager.default
        let placeholderURL = directory.appendingPathComponent("Place your audio files here.txt")
        guard !fileManager.fileExists(atPath: placeholderURL.path) else { return }
        let message = """
        Hello! 👋
        
        You can add your music files to this folder (or any subfolder) and Naa Paata will find them automatically.
        
        Supported formats:
        MP3, M4A, AAC, WAV, AIFF, CAF, FLAC, OGG, OPUS, WMA, ALAC
        
        Just drag and drop your files here using the Files app or iTunes File Sharing.
        
        Enjoy your music! 🎵
        """
        do {
            try message.write(to: placeholderURL, atomically: true, encoding: .utf8)
            print("📄 Created placeholder file: \(placeholderURL.lastPathComponent)")
        } catch {
            print("⚠️ Could not create placeholder file: \(error)")
        }
    }
}
