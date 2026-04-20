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
    
    /// Many-to-many relationship with Song
    @Relationship(deleteRule: .cascade) var songs: [Song] = []
    
    var coverImageData: Data?
    var desc: String
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        name: String,
        songs: [Song] = [],
        coverImage: UIImage? = nil,
        desc: String = "",
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.songs = songs
        self.coverImageData = coverImage?.jpegData(compressionQuality: 0.9)
        self.desc = desc
        self.dateCreated = dateCreated
    }
    
    var coverImage: UIImage? {
        guard let data = coverImageData else { return nil }
        return UIImage(data: data)
    }
    
    /// Check if this is the Favorites playlist
    var isFavoritesPlaylist: Bool {
        name == "Favorites"
    }
}

enum SortOption: String, CaseIterable {
    case dateAdded = "Date Added"
    case title = "Title"
    case artist = "Artist"
    case duration = "Duration"
}

