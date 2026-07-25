//
//  PlayListModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import SwiftUI
import SwiftData

@Model
final class Playlist: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String

    /// Stores song membership as relative paths — avoids SwiftData relationship re-parenting.
    /// A song can belong to multiple playlists because paths are plain strings, not object references.
    var songPaths: [String] = []

    var coverImageData: Data?
    var desc: String
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        name: String,
        songPaths: [String] = [],
        coverImage: UIImage? = nil,
        desc: String = "",
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.songPaths = songPaths
        self.coverImageData = coverImage?.jpegData(compressionQuality: 0.9)
        self.desc = desc
        self.dateCreated = dateCreated
    }

    var coverImage: UIImage? {
        guard let data = coverImageData else { return nil }
        return UIImage(data: data)
    }
}

enum SortOption: String, CaseIterable {
    case dateAdded = "Date Added"
    case title = "Title"
    case artist = "Artist"
    case duration = "Duration"
}
