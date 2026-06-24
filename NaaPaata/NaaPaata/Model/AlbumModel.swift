//
//  AlbumModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/18/25.
//

import Foundation
import SwiftUI

struct Album: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    var artworkImage: UIImage? = nil
    var songs: [Song]
    
    var dateAdded: Date
    var dateModified: Date
    var totalSize: Int64
    
    var artwork: Image {
        if let uiImage = artworkImage {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "opticaldisc")
        }
    }
    
    init(name: String, artist: String, songs: [Song], artworkImage: UIImage? = nil, dateAdded: Date, dateModified: Date, totalSize: Int64 = 0) {
        self.name = name
        self.artist = artist
        self.songs = songs
        self.artworkImage = artworkImage
        self.dateAdded = dateAdded
        self.dateModified = dateModified
        self.totalSize = totalSize
    }
}
