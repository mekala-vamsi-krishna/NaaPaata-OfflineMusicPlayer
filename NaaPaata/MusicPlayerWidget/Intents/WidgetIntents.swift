
//
//  WidgetIntents.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/26/26.
//

import AppIntents

struct PlayPauseIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Play or Pause"
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.writeCommand(.playPause)
        return .result()
    }
}

struct NextIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Next Song"
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.writeCommand(.next)
        return .result()
    }
}

struct PreviousIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Previous Song"
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.writeCommand(.previous)
        return .result()
    }
}
