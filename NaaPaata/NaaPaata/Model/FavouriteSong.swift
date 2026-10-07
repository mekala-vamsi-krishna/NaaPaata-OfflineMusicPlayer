//
//  FavouriteSong.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import Foundation
import SwiftData

@Model
final class FavouriteSong {

    /// Path of the song relative to the app's music folder.
    /// Absolute paths can't be stored — see `DocumentFolderService`.
    @Attribute(.unique) var songRelativePath: String

    /// When the user favourited this song. Used for "recently added" sorting.
    var dateAdded: Date

    init(songRelativePath: String, dateAdded: Date = Date()) {
        self.songRelativePath = songRelativePath
        self.dateAdded = dateAdded
    }
}
