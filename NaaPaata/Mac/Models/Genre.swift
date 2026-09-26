//
//  Genre.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation

struct Genre: Identifiable {
    let id: String
    let name: String
    let songs: [Song]

    /// First song with artwork, used for the card background
    var artworkData: Data? {
        songs.first(where: { $0.artworkData != nil })?.artworkData
    }

    var songCount: Int { songs.count }

    var subtitle: String {
        "\(songCount) song\(songCount == 1 ? "" : "s")"
    }
}

// MARK: - Identity-based hashing

extension Genre: Hashable {
    static func == (lhs: Genre, rhs: Genre) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
