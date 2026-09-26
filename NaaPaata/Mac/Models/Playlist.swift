//
//  Playlist.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import Foundation
import SwiftData

@Model
final class Playlist {

    var name: String
    var descr: String
    @Attribute(.externalStorage) var artworkData: Data?
    /// Stored as file paths so the model is fully persistable.
    var songPaths: [String]
    var createdAt: Date

    init(
        name: String,
        description: String = "",
        artworkData: Data? = nil,
        songPaths: [String] = [],
        createdAt: Date = Date()
    ) {
        self.name = name
        self.descr = description
        self.artworkData = artworkData
        self.songPaths = songPaths
        self.createdAt = createdAt
    }

    var songURLs: [URL] { songPaths.map { URL(fileURLWithPath: $0) } }
    var songCount: Int { songPaths.count }

    var subtitle: String {
        let count = songCount
        let songsLabel = "\(count) song\(count == 1 ? "" : "s")"
        return descr.isEmpty ? songsLabel : "\(songsLabel) • \(descr)"
    }

    func contains(_ url: URL) -> Bool {
        songPaths.contains(url.path)
    }
}
