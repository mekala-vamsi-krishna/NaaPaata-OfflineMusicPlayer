//
//  PlayListModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import SwiftUI
import SwiftData

@Model
final class Playlist {

    @Attribute(.unique) var id: UUID
    var name: String
    var desc: String
    var coverImageData: Data?
    var dateCreated: Date

    /// Paths **relative to the app's Documents directory**, e.g.
    /// `song.mp3` or `Albums/track.m4a`. Relative — not absolute — so
    /// the playlist survives container UUID changes across installs.
    var songRelativePaths: [String]

    init(
        id: UUID = UUID(),
        name: String,
        desc: String = "",
        coverImageData: Data? = nil,
        dateCreated: Date = Date(),
        songRelativePaths: [String] = []
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.coverImageData = coverImageData
        self.dateCreated = dateCreated
        self.songRelativePaths = songRelativePaths
    }

    var songCount: Int { songRelativePaths.count }
}

enum SortOption: String, CaseIterable {
    case dateAdded = "Date Added"
    case title = "Title"
    case artist = "Artist"
    case duration = "Duration"
}
