//
//  PlaySession.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/25/26.
//

import Foundation
import SwiftData

@Model
final class PlaySession {

    var songPath: String
    var startedAt: Date
    var duration: TimeInterval

    init(
        songPath: String,
        startedAt: Date = Date(),
        duration: TimeInterval = 0
    ) {
        self.songPath = songPath
        self.startedAt = startedAt
        self.duration = duration
    }
}
