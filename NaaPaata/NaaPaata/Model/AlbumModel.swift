//
//  AlbumModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation

struct Album: Identifiable {
    let id: String
    let title: String
    let artist: String
    let songs: [Song]

    var artworkData: Data? {
        songs.first(where: { $0.artworkData != nil })?.artworkData
    }

    var trackCount: Int { songs.count }

    var totalDuration: TimeInterval {
        songs.compactMap(\.duration).reduce(0, +)
    }

    var subtitle: String {
        "\(trackCount) song\(trackCount == 1 ? "" : "s")"
    }
}

extension Album: Hashable {
    static func == (lhs: Album, rhs: Album) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
