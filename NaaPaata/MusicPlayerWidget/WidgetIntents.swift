
//
//  WidgetIntents.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/26/26.
//

import AppIntents
import Foundation
import WidgetKit

struct PlayPauseIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Play/Pause"
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        MusicPlayerManager.shared.togglePlayPause()
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        return .result()
    }
}

struct NextIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Next"
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        MusicPlayerManager.shared.playNext()
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        return .result()
    }
}

struct PreviousIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Previous"
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        MusicPlayerManager.shared.playPrevious()
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        return .result()
    }
}
