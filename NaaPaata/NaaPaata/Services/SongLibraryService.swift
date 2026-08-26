//
//  LoadAllSongsFromDocuments.swift
//  NaaPaata
//
//  Created by User on 05/10/25.
//

import Foundation
import SwiftData
import AVFoundation
import UIKit

/// The one service that handles everything related to loading songs from disk.
@MainActor
final class SongLibraryService {
    private let dataService: DataServiceProtocol
    
    private let audioExtensions = Set(["mp3", "m4a", "aac", "wav", "aiff", "caf", "flac", "ogg", "opus", "wma", "alac"])
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    func loadAllSongs(progressHandler: ((Double) -> Void)? = nil) async -> [Song] {
            let diskFiles = scanAudioFiles()
            let dbSongs = dataService.fetchSongs()
            let dbPaths = Set(dbSongs.map { $0.relativePath })
            let diskPaths = Set(diskFiles.map { $0.relativePath })

            let newPaths = diskPaths.subtracting(dbPaths)
            let deletedPaths = dbPaths.subtracting(diskPaths)

            if !deletedPaths.isEmpty {
                let songsToDelete = dbSongs.filter { deletedPaths.contains($0.relativePath) }
                dataService.deleteSongs(songsToDelete)
            }

            if !newPaths.isEmpty {
                let newFiles = diskFiles.filter { newPaths.contains($0.relativePath) }
                let newSongs = await extractMetadata(for: newFiles, progress: progressHandler)
                for song in newSongs {
                    dataService.saveSong(song)
                }
            }

            // Update absolute paths if changed
            for song in dbSongs {
                if let matchingFile = diskFiles.first(where: { $0.relativePath == song.relativePath }) {
                    let newURLString = matchingFile.url.path
                    if song.urlString != newURLString {
                        song.urlString = newURLString
                        dataService.saveSong(song)
                    }
                }
            }

            return dataService.fetchSongs()
        }

    // MARK: - scanAudioFiles
    /// Scans the Documents folder for audio files and returns (URL, relativePath) pairs.
    private func scanAudioFiles() -> [(url: URL, relativePath: String)] {
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        let docsPath = docsURL.path + "/"

        guard let enumerator = fileManager.enumerator(
            at: docsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

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
        return results
    }

    /// Extracts metadata from a list of files concurrently, reporting progress.
    private func extractMetadata(for files: [(url: URL, relativePath: String)], progress: ((Double) -> Void)?) async -> [Song] {
        guard !files.isEmpty else { return [] }
        var songs: [Song] = []
        songs.reserveCapacity(files.count)

        let total = files.count
        var completed = 0

        await withTaskGroup(of: Song?.self) { group in
            for file in files {
                group.addTask {
                    await self.extractSongMetadata(from: file.url, relativePath: file.relativePath)
                }
            }

            for await song in group {
                if let song = song {
                    songs.append(song)
                }
                completed += 1
                let currentProgress = Double(completed) / Double(total)
                progress?(currentProgress)
            }
        }

        progress?(1.0)
        return songs
    }

    /// Extracts metadata from a single audio file.
    private func extractSongMetadata(from url: URL, relativePath: String) async -> Song? {
        let asset = AVAsset(url: url)
        do {
            let duration = try await asset.load(.duration).seconds
            let metadata = try await asset.load(.commonMetadata)

            // Helper to extract string metadata
            func string(for key: AVMetadataKey) -> String? {
                return AVMetadataItem.metadataItems(from: metadata, withKey: key, keySpace: .common)
                    .first?.stringValue
            }

            let title = string(for: .commonKeyTitle) ?? url.deletingPathExtension().lastPathComponent
            let artist = string(for: .commonKeyArtist) ?? "Unknown Artist"
            let album = string(for: .commonKeyAlbumName) ?? "Unknown Album"

            // Extract artwork
            var artwork: UIImage?
            let artworkItems = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: .common)
            if let artItem = artworkItems.first, let data = artItem.value as? Data {
                artwork = UIImage(data: data)
            }

            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let dateAdded = attributes?[.creationDate] as? Date ?? Date()

            return Song(
                relativePath: relativePath,
                urlString: url.path,
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                artworkImage: artwork,
                dateAdded: dateAdded
            )
        } catch {
            print("⚠️ Failed to extract metadata from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
}
