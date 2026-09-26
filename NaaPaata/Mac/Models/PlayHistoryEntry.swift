//
//  PlayHistoryEntry.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import Foundation
import SwiftData

@Model
final class PlayHistoryEntry {

    @Attribute(.unique) var songPath: String
    var playCount: Int
    var lastPlayedAt: Date

    init(songPath: String, playCount: Int = 0, lastPlayedAt: Date = .distantPast) {
        self.songPath = songPath
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
    }
}
