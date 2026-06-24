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
    @Attribute(.unique) var relativePath: String
    var urlString: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var artworkData: Data?
    var dateAdded: Date
    var bookmarkData: Data?

    init(id: UUID = UUID(),
         relativePath: String,
         urlString: String,
         title: String,
         artist: String,
         album: String = "Unknown Album",
         duration: TimeInterval,
         artworkImage: UIImage? = nil,
         dateAdded: Date = Date(),
         bookmarkData: Data? = nil) {
        self.id = id
        self.relativePath = relativePath
        self.urlString = urlString
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkData = artworkImage?.jpegData(compressionQuality: 0.9)
        self.dateAdded = dateAdded
        self.bookmarkData = bookmarkData
        if bookmarkData == nil, let url = URL(string: urlString) {
            self.bookmarkData = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
    }
    
    convenience init(url: URL,
                     title: String,
                     artist: String,
                     album: String = "Unknown Album",
                     duration: TimeInterval,
                     artworkImage: UIImage? = nil,
                     dateAdded: Date = Date()) {
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path + "/"
        let relativePath = url.path.replacingOccurrences(of: docsPath, with: "")
        self.init(relativePath: relativePath,
                  urlString: url.absoluteString,
                  title: title,
                  artist: artist,
                  album: album,
                  duration: duration,
                  artworkImage: artworkImage,
                  dateAdded: dateAdded)
    }

    var url: URL? {
        URL(string: urlString)
    }
    
    var artworkImage: UIImage? {
        guard let data = artworkData else { return nil }
        return UIImage(data: data)
    }
    
    var resolvedURL: URL? {
        if let bookmarkData = bookmarkData, let url = url {
            var isStale = false
            if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                return resolvedURL
            }
        }
        return url
    }
}
