//
//  FavouriteSong.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/17/26.
//

import Foundation
import SwiftData

@Model
final class FavouriteSong {

    @Attribute(.unique) var songPath: String
    var dateAdded: Date

    init(songPath: String, dateAdded: Date = Date()) {
        self.songPath = songPath
        self.dateAdded = dateAdded
    }
}
