//
//  SongModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import SwiftUI
import SwiftData

@Model
final class Song: Identifiable {
    @Attribute(.unique) var id: UUID
    
    // File reference - stored as string for SwiftData compatibility
    @Attribute(.unique) var urlString: String
    
    var title: String
    var artist: String
    var duration: TimeInterval
    var artworkData: Data?
    var dateAdded: Date
    var bookmarkData: Data?

    init(
        id: UUID = UUID(),
        urlString: String,
        title: String,
        artist: String,
        duration: TimeInterval,
        artworkImage: UIImage? = nil,
        dateAdded: Date = Date(),
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.urlString = urlString
        self.title = title
        self.artist = artist
        self.duration = duration
        self.artworkData = artworkImage?.jpegData(compressionQuality: 0.9)
        self.dateAdded = dateAdded
        self.bookmarkData = bookmarkData
        
        // Create security scoped bookmark if not provided
        if bookmarkData == nil, let url = URL(string: urlString) {
            self.bookmarkData = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
    }
    
    /// Convenience initializer for URL objects (backward compatibility)
    convenience init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        artist: String,
        duration: TimeInterval,
        artworkImage: UIImage? = nil,
        dateAdded: Date = Date()
    ) {
        self.init(
            id: id,
            urlString: url.absoluteString,
            title: title,
            artist: artist,
            duration: duration,
            artworkImage: artworkImage,
            dateAdded: dateAdded
        )
    }

    // Convenience property to get URL from string
    var url: URL? {
        URL(string: urlString)
    }
    
    var artworkImage: UIImage? {
        guard let data = artworkData else { return nil }
        return UIImage(data: data)
    }
    
    // Get the actual file URL, resolving from bookmark if needed
    var resolvedURL: URL? {
        if let bookmarkData = bookmarkData, let url = url {
            var isStale = false
            if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                return resolvedURL
            }
        }
        // Fallback to URL from string
        return url
    }
}
