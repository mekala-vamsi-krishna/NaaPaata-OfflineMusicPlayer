//
//  LibraryCacheManager.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/30/26.
//

import Foundation

final class LibraryCacheManager {
    static let shared = LibraryCacheManager()
    
    private let cacheFileName = "library_cache.json"
    
    private var cacheURL: URL? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appSupport.appendingPathComponent(cacheFileName)
    }
    
    func save(_ songs: [Song]) {
        guard let url = cacheURL else { return }
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save library cache: \(error)")
        }
    }
    
    func load() -> [Song]? {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let songs = try JSONDecoder().decode([Song].self, from: data)
            return songs
        } catch {
            print("Failed to load library cache: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        guard let url = cacheURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
