//
//  SharedDataManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/26/26.
//

import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let appGroup = "group.com.NaaPaata.mp3"
    private let userDefaults: UserDefaults?
    
    private let songTitleKey = "widget_song_title"
    private let artistKey = "widget_artist"
    private let artworkDataKey = "widget_artwork"
    private let isPlayingKey = "widget_is_playing"
    private let timestampKey = "widget_timestamp"
    
    // Command keys for intents
    private let commandKey = "widget_command"
    private let commandTimestampKey = "widget_command_timestamp"
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroup)
    }
    
    // MARK: - Write data (new signature)
    func updateWidgetData(title: String?, artist: String?, artworkData: Data?, isPlaying: Bool) {
        guard let defaults = userDefaults else { return }
        if let title = title {
            defaults.set(title, forKey: songTitleKey)
        } else {
            defaults.removeObject(forKey: songTitleKey)
        }
        if let artist = artist {
            defaults.set(artist, forKey: artistKey)
        } else {
            defaults.removeObject(forKey: artistKey)
        }
        if let artworkData = artworkData {
            defaults.set(artworkData, forKey: artworkDataKey)
        } else {
            defaults.removeObject(forKey: artworkDataKey)
        }
        defaults.set(isPlaying, forKey: isPlayingKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }
    
    // MARK: - Read data
    func getWidgetData() -> (title: String?, artist: String?, artworkData: Data?, isPlaying: Bool) {
        guard let defaults = userDefaults else {
            return (nil, nil, nil, false)
        }
        let title = defaults.string(forKey: songTitleKey)
        let artist = defaults.string(forKey: artistKey)
        let artworkData = defaults.data(forKey: artworkDataKey)
        let isPlaying = defaults.bool(forKey: isPlayingKey)
        return (title, artist, artworkData, isPlaying)
    }
    
    // MARK: - Command handling for intents
    func writeCommand(_ command: String) {
        guard let defaults = userDefaults else { return }
        defaults.set(command, forKey: commandKey)
        defaults.set(Date().timeIntervalSince1970, forKey: commandTimestampKey)
        // Post Darwin notification to wake the app
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.NaaPaata.widgetCommand" as CFString),
            nil,
            nil,
            true
        )
    }
    
    func readCommand() -> String? {
        guard let defaults = userDefaults else { return nil }
        // Only return command if it's fresh (within last 2 seconds)
        let timestamp = defaults.double(forKey: commandTimestampKey)
        if Date().timeIntervalSince1970 - timestamp < 2.0 {
            return defaults.string(forKey: commandKey)
        }
        return nil
    }
    
    func clearCommand() {
        guard let defaults = userDefaults else { return }
        defaults.removeObject(forKey: commandKey)
        defaults.removeObject(forKey: commandTimestampKey)
    }
}
