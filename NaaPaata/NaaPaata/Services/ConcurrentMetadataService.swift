//
//  ConcurrentMetadataService.swift
//  NaaPaata
//
//  Created by Assistant on 04/20/26.
//

import Foundation
import AVFoundation
import UIKit

actor ConcurrentMetadataService {
    static let shared = ConcurrentMetadataService()
    
    private var cache: [String: Song] = [:]
    
    private let maxCacheSize = 2000
    
    // MARK: - loadSongsMetadata
    func loadSongsMetadata(urls: [URL], progressHandler: (@Sendable (Double) -> Void)? = nil) async -> [Song] {
        guard !urls.isEmpty else { return [] }
        var songs: [Song] = []
        songs.reserveCapacity(urls.count)
        var completed = 0
        var lastReportedProgress: Double = -1.0
        let throttleThreshold = 0.02
        
        await withTaskGroup(of: Song?.self) { group in
            for url in urls {
                group.addTask {
                    await self.extractMetadata(for: url)
                }
            }
            for await song in group {
                if let song = song {
                    songs.append(song)
                }
                completed += 1
                let progress = Double(completed) / Double(urls.count)
                if progress - lastReportedProgress >= throttleThreshold || completed == urls.count {
                    lastReportedProgress = progress
                    progressHandler?(progress)
                }
            }
        }
        progressHandler?(1.0)
        return songs
    }
    
    // MARK: - extractMetadata for url
    func extractMetadata(for url: URL) async -> Song? {
        let path = url.path
        if let cached = cache[path] { return cached }
        
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let docsPath = docsURL.path + "/"
        var relativePath = path.replacingOccurrences(of: docsPath, with: "")
        if relativePath.isEmpty {
            relativePath = url.lastPathComponent
        }
        
        let asset = AVAsset(url: url)
        do {
            let duration = try await asset.load(.duration).seconds
            let metadata = try await asset.load(.commonMetadata)
            
            // Extract title, artist, album
            func extractString(for key: AVMetadataKey) -> String? {
                return AVMetadataItem.metadataItems(from: metadata, withKey: key, keySpace: .common)
                    .first?.stringValue
            }
            
            let title = extractString(for: .commonKeyTitle) ?? url.deletingPathExtension().lastPathComponent
            let artist = extractString(for: .commonKeyArtist) ?? "Unknown Artist"
            let album = extractString(for: .commonKeyAlbumName) ?? "Unknown Album"
            
            // Extract artwork – use value as? Data
            var artwork: UIImage? = nil
            let artworkItems = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: .common)
            if let artItem = artworkItems.first,
               let artData = artItem.value as? Data {
                artwork = UIImage(data: artData)
            }
            
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            let dateAdded = attributes?[.creationDate] as? Date ?? Date()
            
            let song = Song(
                relativePath: relativePath,
                urlString: path,
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                artworkImage: artwork,
                dateAdded: dateAdded
            )
            cache[path] = song
            trimCacheIfNeeded()
            return song
        } catch {
            print("⚠️ Error extracting metadata for \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - trimCacheIfNeeded
    private func trimCacheIfNeeded() {
        if cache.count > maxCacheSize {
            let toRemove = cache.count - maxCacheSize
            let keysToRemove = Array(cache.keys.prefix(toRemove))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    // MARK: - clearCache
    func clearCache() {
        cache.removeAll()
    }
}
