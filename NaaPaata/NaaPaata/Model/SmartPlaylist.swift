//
//  SmartPlaylist.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/9/26.
//

import SwiftUI

struct SmartPlaylist: Identifiable {
    let kind: SmartPlaylistKind
    let songs: [Song]

    var id: String { kind.rawValue }
    var title: String { kind.title }
    var symbol: String { kind.systemImage }
    var gradient: LinearGradient { kind.gradient }
    var songCount: Int { songs.count }

    var subtitle: String {
        let count = songs.count
        return "\(count) song\(count == 1 ? "" : "s")"
    }

    var isEmpty: Bool { songs.isEmpty }

    var artworkData: Data? {
        songs.first(where: { $0.artworkData != nil })?.artworkData
    }
}
