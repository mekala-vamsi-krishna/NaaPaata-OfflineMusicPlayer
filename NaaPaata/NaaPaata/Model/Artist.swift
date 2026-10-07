//
//  Artist.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import Foundation

struct Artist: Identifiable {

    let id: String
    let name: String
    let songs: [Song]

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

    var subtitle: String {
        let songLabel = "\(songCount) song\(songCount == 1 ? "" : "s")"
        let albumLabel = "\(albumCount) album\(albumCount == 1 ? "" : "s")"
        return "\(songLabel) • \(albumLabel)"
    }

    var formattedTotalDuration: String {
        let total = Int(totalDuration)
        guard total > 0 else { return "—" }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Identity-based hashing

extension Artist: Hashable {
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#if canImport(UIKit)
import UIKit

extension Artist {
    /// Platform-specific artwork accessor for iOS views.
    var artworkImage: UIImage? {
        guard let data = artworkData else { return nil }
        return UIImage(data: data)
    }
}
#endif
