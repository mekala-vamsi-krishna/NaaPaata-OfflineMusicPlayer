//
//  Song.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation

struct Song: Identifiable, Hashable {
    let url: URL
    let title: String
    let artist: String
    let album: String
    let genre: String
    let duration: TimeInterval?
    let artworkData: Data?
    let dateAdded: Date 

    var id: URL { url }

    var formattedDuration: String {
        guard let duration, duration.isFinite, duration > 0 else { return "--:--" }
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
