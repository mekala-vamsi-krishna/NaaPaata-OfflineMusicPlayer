//
//  Album.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation

struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let songs: [Song]

    var artworkData: Data? {
        songs.first(where: { $0.artworkData != nil })?.artworkData
    }

    var mostRecentDateAdded: Date {
        songs.map(\.dateAdded).max() ?? .distantPast
    }
    
    var trackCount: Int { songs.count }
    var totalDuration: TimeInterval { songs.compactMap(\.duration).reduce(0, +) }
}
