//
//  Artist.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation

struct Artist: Identifiable {
    let id: String
    let name: String
    let songs: [Song]

    /// First song that carries artwork — used for the row thumbnail.
    var artworkData: Data? {
        songs.first(where: { $0.artworkData != nil })?.artworkData
    }

    var songCount: Int { songs.count }

    var albumCount: Int {
        Set(songs.map(\.album)).count
    }

    var totalDuration: TimeInterval {
        songs.compactMap(\.duration).reduce(0, +)
    }

    /// "12 songs • 3 albums" style subtitle for list rows.
    var subtitle: String {
        let songLabel = "\(songCount) song\(songCount == 1 ? "" : "s")"
        let albumLabel = "\(albumCount) album\(albumCount == 1 ? "" : "s")"
        return "\(songLabel) • \(albumLabel)"
    }
}

// MARK: - Identity-based hashing (avoids hashing artwork blobs)

extension Artist: Hashable {
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
