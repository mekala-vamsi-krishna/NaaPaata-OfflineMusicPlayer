//
//  MusicLibraryService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation
import AVFoundation

protocol MusicLibraryServiceProtocol {
    /// Scans the library folder and returns a sorted list of songs.
    func loadLibrary() async throws -> [Song]
    func delete(_ song: Song) throws
    var libraryFolderURL: URL { get }
}

/// Scans `~/Music/Naa Paata`, reads ID3/metadata, and produces `Song` values.
final class MusicLibraryService: MusicLibraryServiceProtocol {

    private let folderService: MusicFolderService

    /// Extensions we treat as playable audio.
    private static let supportedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aif", "aiff", "caf",
        "flac", "alac", "ogg", "oga", "opus"
    ]

    init(folderService: MusicFolderService) {
        self.folderService = folderService
    }

    var libraryFolderURL: URL { folderService.naaPaataFolderURL }

    // MARK: - Public

    func loadLibrary() async throws -> [Song] {
        let folder = try folderService.ensureNaaPaataFolderExists()
        let urls = Self.audioFileURLs(in: folder)

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
    
    func delete(_ song: Song) throws {
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: song.url, resultingItemURL: &resultingURL)
    }

    // MARK: - File discovery

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
            guard supportedExtensions.contains(url.pathExtension.lowercased()) else { continue }
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

        if let cmDuration = try? await asset.load(.duration),
           cmDuration.isNumeric {
            let seconds = CMTimeGetSeconds(cmDuration)
            if seconds.isFinite, seconds > 0 { duration = seconds }
        }

        // Common metadata (title, artist, album, artwork)
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

        // Genre — not a common key, so scan metadata identifiers
        if let metadata = try? await asset.load(.metadata) {
            for item in metadata {
                guard let identifier = item.identifier else { continue }

                switch identifier {
                case .id3MetadataContentType,
                     .iTunesMetadataUserGenre,
                     .quickTimeMetadataGenre,
                     .quickTimeUserDataGenre:
                    if let raw = try? await item.load(.stringValue) {
                        let cleaned = Self.cleanGenre(raw)
                        if !cleaned.isEmpty {
                            genre = cleaned
                        }
                    }
                default:
                    break
                }

                // Stop early if we already found one.
                if genre != "Unknown Genre" { break }
            }
        }

        let dateAdded: Date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate)
            ?? (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
            ?? .distantPast

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

    /// ID3v1 genres can be numeric like "(17)" or bracketed like "(17)Rock".
    /// Strip those to get a clean string.
    private static func cleanGenre(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle "(17)" or "(17)Rock" style.
        if value.hasPrefix("(") {
            if let close = value.firstIndex(of: ")") {
                let after = value.index(after: close)
                let remainder = String(value[after...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainder.isEmpty {
                    value = remainder
                } else {
                    // Pure numeric — map a few common ID3v1 codes.
                    let code = value.dropFirst().prefix(while: { $0 != ")" })
                    value = Self.id3v1GenreName(for: String(code)) ?? ""
                }
            }
        }

        // Some files use "/" or ";" for multi-genre — take the first.
        if let first = value.split(whereSeparator: { $0 == "/" || $0 == ";" }).first {
            value = String(first).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }

    private static func id3v1GenreName(for code: String) -> String? {
        // Minimal mapping — expand if needed.
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
