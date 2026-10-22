//
//  SongModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import Foundation

struct Song: Identifiable {
    var id: URL { url }
    let url: URL
    let title: String
    let artist: String
    let album: String
    let genre: String
    let duration: TimeInterval?
    let artworkData: Data?
    let dateAdded: Date
    var lyrics: String?


    var formattedDuration: String {
        guard let duration, duration.isFinite, duration > 0 else { return "--:--" }
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

extension Song: Hashable {
    static func == (lhs: Song, rhs: Song) -> Bool { lhs.url == rhs.url }
    func hash(into hasher: inout Hasher) { hasher.combine(url) }
}
