//
//  MusicLibraryService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation
import AVFoundation

protocol MusicLibraryServiceProtocol {
    var libraryFolderURL: URL { get }
    func loadLibrary() async throws -> [Song]
    func delete(_ song: Song) throws
}

/// Scans the app's Documents directory for audio files and extracts
/// metadata from each.
final class MusicLibraryService: MusicLibraryServiceProtocol {

    private let rootFolder: URL

    private static let supportedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aif", "aiff", "caf",
        "flac", "alac", "ogg", "oga", "opus"
    ]

    init(rootFolder: URL) {
        self.rootFolder = rootFolder
    }

    var libraryFolderURL: URL { rootFolder }

    // MARK: - Load

    func loadLibrary() async throws -> [Song] {
        let urls = Self.audioFileURLs(in: rootFolder)

        return await withTaskGroup(of: Song?.self, returning: [Song].self) { group in
            for url in urls {
                group.addTask { await Self.makeSong(from: url) }
            }

            var songs: [Song] = []
            songs.reserveCapacity(urls.count)

            for await song in group {
                if let song { songs.append(song) }
            }

            return songs.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
    }

    // MARK: - Delete

    func delete(_ song: Song) throws {
        try FileManager.default.removeItem(at: song.url)
    }

    // MARK: - Discovery

    private static func audioFileURLs(in folder: URL) -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]

        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard supportedExtensions.contains(ext) else { continue }
            urls.append(url)
        }
        return urls
    }

    // MARK: - Metadata

    private static func makeSong(from url: URL) async -> Song? {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )

        var title  = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album  = "Unknown Album"
        var genre  = "Unknown Genre"
        var duration: TimeInterval?
        var artworkData: Data?

        // Duration
        if let cmDuration = try? await asset.load(.duration), cmDuration.isNumeric {
            let seconds = CMTimeGetSeconds(cmDuration)
            if seconds.isFinite, seconds > 0 { duration = seconds }
        }

        // Common metadata
        if let commonMetadata = try? await asset.load(.commonMetadata) {
            for item in commonMetadata {
                guard let key = item.commonKey else { continue }

                if key == .commonKeyArtwork {
                    if let data = try? await item.load(.dataValue) {
                        artworkData = data
                    }
                    continue
                }

                guard let value = try? await item.load(.stringValue),
                      !value.trimmingCharacters(in: .whitespaces).isEmpty
                else { continue }

                switch key {
                case .commonKeyTitle:     title  = value
                case .commonKeyArtist:    artist = value
                case .commonKeyAlbumName: album  = value
                default: break
                }
            }
        }

        // Genre — scanned by identifier
        if let metadata = try? await asset.load(.metadata) {
            for item in metadata {
                guard let identifier = item.identifier else { continue }

                switch identifier {
                case .id3MetadataContentType,
                     .iTunesMetadataUserGenre,
                     .quickTimeMetadataGenre,
                     .quickTimeUserDataGenre:
                    if let raw = try? await item.load(.stringValue) {
                        let cleaned = GenreCleaner.clean(raw)
                        if !cleaned.isEmpty { genre = cleaned }
                    }
                default: break
                }

                if genre != "Unknown Genre" { break }
            }
        }

        // Date added
        let dateAdded: Date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate)
            ?? (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
            ?? Date()

        return Song(
            url: url,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            duration: duration,
            artworkData: artworkData,
            dateAdded: dateAdded
        )
    }
}

// MARK: - Genre cleaner (iOS-only helper)

private enum GenreCleaner {
    static func clean(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if value.hasPrefix("(") {
            if let close = value.firstIndex(of: ")") {
                let after = value.index(after: close)
                let remainder = String(value[after...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainder.isEmpty {
                    value = remainder
                } else {
                    let code = value.dropFirst().prefix(while: { $0 != ")" })
                    value = id3v1Name(for: String(code)) ?? ""
                }
            }
        }

        if let first = value.split(whereSeparator: { $0 == "/" || $0 == ";" }).first {
            value = String(first).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private static func id3v1Name(for code: String) -> String? {
        let map: [String: String] = [
            "0": "Blues", "1": "Classical", "2": "Country", "3": "Dance",
            "4": "Disco", "5": "Funk", "6": "Gospel", "7": "Hip-Hop",
            "8": "Jazz", "9": "Metal", "10": "New Age", "11": "Oldies",
            "12": "Other", "13": "Pop", "14": "R&B", "15": "Rap",
            "16": "Reggae", "17": "Rock", "18": "Techno", "19": "Industrial"
        ]
        return map[code]
    }
}
