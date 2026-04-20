//
//  ConcurrentMetadataService.swift
//  NaaPaata
//
//  Created by Assistant on 04/20/26.
//

import Foundation
import AVFoundation
import UIKit

/// Service for loading media metadata concurrently with proper caching and error handling
final class ConcurrentMetadataService {
    static let shared = ConcurrentMetadataService()
    
    // Cache for metadata to avoid re-processing
    private let metadataCache = NSCache<NSString, SongMetadata>()
    private let albumMetadataCache = NSCache<NSString, AlbumMetadata>()
    
    // Concurrent processing queue
    private let processingQueue = DispatchQueue(
        label: "com.naapata.metadataProcessing",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    private init() {
        // Configure cache limits
        metadataCache.countLimit = 1000
        albumMetadataCache.countLimit = 500
    }
    
    // MARK: - Song Metadata
    
    final class SongMetadata {
        let title: String
        let artist: String
        let duration: TimeInterval
        let artwork: UIImage?
        let dateAdded: Date
        let albumName: String?
        
        init(title: String, artist: String, duration: TimeInterval, artwork: UIImage?, dateAdded: Date, albumName: String?) {
            self.title = title
            self.artist = artist
            self.duration = duration
            self.artwork = artwork
            self.dateAdded = dateAdded
            self.albumName = albumName
        }
    }
    
    /// Load metadata for multiple songs concurrently
    func loadSongsMetadata(urls: [URL], progressHandler: (@Sendable (Double) -> Void)? = nil) async throws -> [Song] {
        guard !urls.isEmpty else { return [] }
        
        let batchSize = min(10, urls.count) // Process up to 10 songs concurrently
        var loadedSongs: [Song] = []
        loadedSongs.reserveCapacity(urls.count)
        
        // Process in batches to avoid overwhelming the system
        for batchStart in stride(from: 0, to: urls.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, urls.count)
            let batch = Array(urls[batchStart..<batchEnd])
            
            let batchSongs = try await processSongBatchConcurrently(batch)
            loadedSongs.append(contentsOf: batchSongs)
            
            // Update progress
            let progress = Double(loadedSongs.count) / Double(urls.count)
            progressHandler?(progress)
        }
        
        return loadedSongs
    }
    
    private func processSongBatchConcurrently(_ urls: [URL]) async throws -> [Song] {
        try await withThrowingTaskGroup(of: Song?.self) { group in
            // Add tasks for each URL
            for url in urls {
                group.addTask {
                    await self.processSongMetadata(url)
                }
            }
            
            var results: [Song] = []
            results.reserveCapacity(urls.count)
            
            // Collect results as they complete
            for try await song in group {
                if let song = song {
                    results.append(song)
                }
            }
            
            return results
        }
    }
    
    private func processSongMetadata(_ url: URL) async -> Song? {
        let cacheKey = url.absoluteString as NSString
        
        // Check cache first
        if let cached = metadataCache.object(forKey: cacheKey) {
            return Song(
                url: url,
                title: cached.title,
                artist: cached.artist,
                duration: cached.duration,
                artworkImage: cached.artwork,
                dateAdded: cached.dateAdded
            )
        }
        
        // Process metadata concurrently
        return await Task.detached(priority: .userInitiated) {
            do {
                let asset = AVAsset(url: url)
                
                // Load metadata asynchronously
                let metadata = try await asset.load(.commonMetadata)
                
                // Extract title
                let title = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: .common).first?.stringValue
                    ?? url.lastPathComponent
                
                // Extract artist
                let artist = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtist, keySpace: .common).first?.stringValue
                    ?? "Unknown Artist"
                
                // Extract duration
                let duration = try await asset.load(.duration).seconds
                
                // Extract artwork
                var artwork: UIImage? = nil
                if let artItem = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: .common).first,
                   let artData = artItem.dataValue {
                    artwork = UIImage(data: artData)
                }
                
                // Extract album name
                let albumName = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: .common).first?.stringValue
                
                // Extract file creation date
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let dateAdded = attributes?[.creationDate] as? Date ?? Date()
                
                let songMetadata = SongMetadata(
                    title: title,
                    artist: artist,
                    duration: duration,
                    artwork: artwork,
                    dateAdded: dateAdded,
                    albumName: albumName
                )
                
                // Cache the metadata
                await MainActor.run {
                    self.metadataCache.setObject(songMetadata, forKey: cacheKey)
                }
                
                return Song(
                    url: url,
                    title: title,
                    artist: artist,
                    duration: duration,
                    artworkImage: artwork,
                    dateAdded: dateAdded
                )
                
            } catch {
                print("Error processing song \(url.lastPathComponent): \(error.localizedDescription)")
                return nil
            }
        }.value
    }
    
    // MARK: - Album Metadata
    
    final class AlbumMetadata {
        let name: String
        let artwork: UIImage?
        var songs: [Song]
        let dateAdded: Date
        let dateModified: Date
        
        init(name: String, artwork: UIImage?, songs: [Song], dateAdded: Date, dateModified: Date) {
            self.name = name
            self.artwork = artwork
            self.songs = songs
            self.dateAdded = dateAdded
            self.dateModified = dateModified
        }
    }
    
    /// Load albums from song URLs concurrently
    func loadAlbumsFromSongs(urls: [URL], progressHandler: (@Sendable (Double) -> Void)? = nil) async throws -> [Album] {
        guard !urls.isEmpty else { return [] }
        
        let batchSize = min(8, urls.count) // Process up to 8 files concurrently
        var albumMap: [String: AlbumMetadata] = [:]
        
        // Process in batches
        for batchStart in stride(from: 0, to: urls.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, urls.count)
            let batch = Array(urls[batchStart..<batchEnd])
            
            let batchResults = try await processAlbumBatchConcurrently(batch)
            
            // Merge results into albumMap
            for (albumName, metadata) in batchResults {
                if albumMap[albumName] == nil {
                    albumMap[albumName] = metadata
                } else {
                    // Merge songs into existing album
                    albumMap[albumName]?.songs.append(contentsOf: metadata.songs)
                }
            }
            
            // Update progress
            let progress = Double(batchEnd) / Double(urls.count)
            progressHandler?(progress)
        }
        
        // Convert to Album structs
        return albumMap.map { (name, metadata) in
            Album(
                name: name,
                artworkImage: metadata.artwork,
                songs: metadata.songs,
                dateAdded: metadata.dateAdded,
                dateModified: metadata.dateModified
            )
        }
    }
    
    private func processAlbumBatchConcurrently(_ urls: [URL]) async throws -> [String: AlbumMetadata] {
        try await withThrowingTaskGroup(of: (String, AlbumMetadata)?.self) { group in
            for url in urls {
                group.addTask {
                    await self.processAlbumSong(url)
                }
            }
            
            var results: [String: AlbumMetadata] = [:]
            
            for try await result in group {
                if let (albumName, metadata) = result {
                    results[albumName] = metadata
                }
            }
            
            return results
        }
    }
    
    private func processAlbumSong(_ url: URL) async -> (String, AlbumMetadata)? {
        return await Task.detached(priority: .userInitiated) {
            do {
                let asset = AVAsset(url: url)
                let metadata = try await asset.load(.commonMetadata)
                
                let title = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: .common).first?.stringValue
                    ?? url.deletingPathExtension().lastPathComponent
                
                let artist = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtist, keySpace: .common).first?.stringValue
                    ?? "Unknown Artist"
                
                let duration = try await asset.load(.duration).seconds
                
                var artwork: UIImage? = nil
                if let artItem = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: .common).first,
                   let artData = artItem.dataValue {
                    artwork = UIImage(data: artData)
                }
                
                let albumName = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: .common).first?.stringValue
                    ?? "Unknown Album"
                
                let song = Song(url: url, title: title, artist: artist, duration: duration, artworkImage: artwork)
                
                // Folder attributes
                let folderURL = url.deletingLastPathComponent()
                let folderAttributes = try? FileManager.default.attributesOfItem(atPath: folderURL.path)
                let dateAdded = folderAttributes?[.creationDate] as? Date ?? Date()
                let dateModified = folderAttributes?[.modificationDate] as? Date ?? Date()
                
                let albumMetadata = AlbumMetadata(
                    name: albumName,
                    artwork: artwork,
                    songs: [song],
                    dateAdded: dateAdded,
                    dateModified: dateModified
                )
                
                return (albumName, albumMetadata)
                
            } catch {
                print("Error processing album song \(url.lastPathComponent): \(error.localizedDescription)")
                return nil
            }
        }.value
    }
    
    // MARK: - Utility Methods
    
    /// Find all MP3 files in a directory concurrently
    func findMP3Files(in directory: URL) async throws -> [URL] {
        try await Task.detached {
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                return []
            }
            
            var mp3Files: [URL] = []
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "mp3" {
                    mp3Files.append(fileURL)
                }
            }
            return mp3Files
        }.value
    }
    
    /// Clear all caches
    func clearCache() {
        metadataCache.removeAllObjects()
        albumMetadataCache.removeAllObjects()
    }
}