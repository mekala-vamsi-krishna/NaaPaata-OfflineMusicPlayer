//
//  PlayHistoryEntry.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/9/26.
//

import Foundation
import SwiftData

@Model
final class PlayHistoryEntry {

    /// Path of the song relative to the app's music folder.
    @Attribute(.unique) var songPath: String

    /// Total number of times the song has been played.
    var playCount: Int

    /// When the song was last played.
    var lastPlayedAt: Date

    init(
        songPath: String,
        playCount: Int = 0,
        lastPlayedAt: Date = .distantPast
    ) {
        self.songPath = songPath
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
    }
}
