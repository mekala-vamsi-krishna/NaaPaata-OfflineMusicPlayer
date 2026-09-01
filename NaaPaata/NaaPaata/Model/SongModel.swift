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
        if bookmarkData == nil, let url = Self.parseStoredURL(urlString) {
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
        Self.parseStoredURL(urlString)
    }
    
    var artworkImage: UIImage? {
        guard let data = artworkData else { return nil }
        return UIImage(data: data)
    }
    
    var resolvedURL: URL? {
        if !relativePath.isEmpty,
           let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentsFileURL = documentsURL.appendingPathComponent(relativePath, isDirectory: false)
            if FileManager.default.fileExists(atPath: documentsFileURL.path) {
                return documentsFileURL
            }
        }

        if let bookmarkData {
            var isStale = false
            if let bookmarkURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), FileManager.default.fileExists(atPath: bookmarkURL.path) {
                return bookmarkURL
            }
        }

        guard let url, FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    private static func parseStoredURL(_ value: String) -> URL? {
        guard !value.isEmpty else { return nil }
        if let url = URL(string: value), url.isFileURL {
            return url
        }
        return URL(fileURLWithPath: value)
    }
}
