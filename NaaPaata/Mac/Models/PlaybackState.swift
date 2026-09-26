//
//  PlaybackState.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import Foundation

struct PlaybackState: Codable {

    var currentSongPath: String?
    var elapsed: TimeInterval
    var queuePaths: [String]
    var originalQueuePaths: [String]
    var currentIndex: Int?
    var isShuffled: Bool
    var repeatMode: String
    var savedAt: Date

    static let empty = PlaybackState(
        currentSongPath: nil,
        elapsed: 0,
        queuePaths: [],
        originalQueuePaths: [],
        currentIndex: nil,
        isShuffled: false,
        repeatMode: RepeatMode.off.rawValue,
        savedAt: .distantPast
    )
}
