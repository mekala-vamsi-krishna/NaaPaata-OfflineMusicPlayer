//
//  SharedDataManager.swift
//  NaaPaata
//

import Foundation
import CoreFoundation

final class SharedDataManager {

    static let shared = SharedDataManager()

    // Must match the App Group in Signing & Capabilities on both targets.
    private let appGroup = "group.com.NaaPaata.mp3"

    private let userDefaults: UserDefaults

    // Widget state keys
    private let songTitleKey    = "widget_song_title"
    private let artistKey       = "widget_artist"
    private let artworkDataKey  = "widget_artwork"
    private let isPlayingKey    = "widget_is_playing"
    private let timestampKey    = "widget_timestamp"

    // Command keys
    private let commandKey          = "widget_command"
    private let commandIDKey        = "widget_command_id"
    private let commandTimestampKey = "widget_command_timestamp"

    /// Darwin notification posted by the widget when it writes a command.
    static let widgetCommandNotification = "com.NaaPaata.widgetCommand"

    private init() {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            fatalError("App Group '\(appGroup)' not configured. Add it to Signing & Capabilities on both targets.")
        }
        self.userDefaults = defaults
    }

    // MARK: - Widget state (app writes, widget reads)

    func updateWidgetData(
        title: String?,
        artist: String?,
        artworkData: Data?,
        isPlaying: Bool
    ) {
        if let title {
            userDefaults.set(title, forKey: songTitleKey)
            userDefaults.set(artist ?? "", forKey: artistKey)
            
            if let artworkData = artworkData {
                userDefaults.set(artworkData, forKey: artworkDataKey)
            } else {
                userDefaults.removeObject(forKey: artworkDataKey)
            }
        } else {
            userDefaults.removeObject(forKey: songTitleKey)
        }
        
        userDefaults.set(isPlaying, forKey: isPlayingKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        
        userDefaults.synchronize()
    }
    
    func clearWidgetData() {
        userDefaults.removeObject(forKey: songTitleKey)
        userDefaults.removeObject(forKey: artistKey)
        userDefaults.removeObject(forKey: artworkDataKey)
        userDefaults.set(false, forKey: isPlayingKey)
        userDefaults.synchronize()
    }

    func getWidgetData() -> WidgetData {
        WidgetData(
            title: userDefaults.string(forKey: songTitleKey),
            artist: userDefaults.string(forKey: artistKey),
            artworkData: userDefaults.data(forKey: artworkDataKey),
            isPlaying: userDefaults.bool(forKey: isPlayingKey)
        )
    }

    // MARK: - Commands (widget writes, app reads)

    func writeCommand(_ command: WidgetCommand) {
        userDefaults.set(command.rawValue, forKey: commandKey)
        userDefaults.set(UUID().uuidString, forKey: commandIDKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: commandTimestampKey)
        userDefaults.synchronize()

        // Wake the app process.
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.widgetCommandNotification as CFString),
            nil,
            nil,
            true
        )
    }

    func readCommand() -> WidgetCommandEnvelope? {
        guard
            let rawValue = userDefaults.string(forKey: commandKey),
            let command = WidgetCommand(rawValue: rawValue),
            let commandID = userDefaults.string(forKey: commandIDKey)
        else { return nil }

        let timestamp = userDefaults.double(forKey: commandTimestampKey)

        // Ignore stale commands (> 30 seconds old).
        guard timestamp > 0,
              Date().timeIntervalSince1970 - timestamp < 30
        else { return nil }

        return WidgetCommandEnvelope(
            id: commandID,
            command: command,
            timestamp: timestamp
        )
    }

    func clearCommand() {
        userDefaults.removeObject(forKey: commandKey)
        userDefaults.removeObject(forKey: commandIDKey)
        userDefaults.removeObject(forKey: commandTimestampKey)
        userDefaults.synchronize()
    }
}

// MARK: - Public types

struct WidgetData {
    let title: String?
    let artist: String?
    let artworkData: Data?
    let isPlaying: Bool
}

enum WidgetCommand: String {
    case playPause
    case next
    case previous
}

struct WidgetCommandEnvelope {
    let id: String
    let command: WidgetCommand
    let timestamp: TimeInterval
}
