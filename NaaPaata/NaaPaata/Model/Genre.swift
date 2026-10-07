//
//  Genre.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI

struct Genre: Identifiable {

    let id: String
    let name: String
    let songs: [Song]

    /// First song with artwork, used for the card background.
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

// MARK: - iOS artwork accessor

extension Genre {
    var artworkImage: UIImage? {
        guard let data = artworkData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Detail-view helpers

extension Genre {

    var albumCount: Int {
        Set(songs.map(\.album)).count
    }

    var artistCount: Int {
        Set(songs.map(\.artist)).count
    }

    var totalDuration: TimeInterval {
        songs.compactMap(\.duration).reduce(0, +)
    }

    var formattedTotalDuration: String {
        let total = Int(totalDuration)
        guard total > 0 else { return "—" }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours) hr \(minutes) min" : "\(minutes) min"
    }
}
