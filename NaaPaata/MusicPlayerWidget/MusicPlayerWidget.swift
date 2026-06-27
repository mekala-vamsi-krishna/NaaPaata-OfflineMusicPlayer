//
//  MusicPlayerWidget.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/26/26.
//

import WidgetKit
import SwiftUI
import UIKit
import AppIntents

// MARK: - Widget Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let title: String?
    let artist: String?
    let artworkData: Data?
    let isPlaying: Bool
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(),
                    title: "Song Title",
                    artist: "Artist",
                    artworkData: nil,
                    isPlaying: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let data = SharedDataManager.shared.getWidgetData()
        print("📸 Snapshot: title=\(data.title ?? "nil"), isPlaying=\(data.isPlaying)")
        let entry = WidgetEntry(date: Date(),
                                title: data.title,
                                artist: data.artist,
                                artworkData: data.artworkData,
                                isPlaying: data.isPlaying)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        let data = SharedDataManager.shared.getWidgetData()
        print("📅 Timeline: title=\(data.title ?? "nil"), isPlaying=\(data.isPlaying)")
        
        // Debug: read test value
        let test = UserDefaults(suiteName: "group.com.NaaPaata.mp3")?.string(forKey: "debug_test")
        print("🔍 Debug test: \(test ?? "nil")")
        
        let entry = WidgetEntry(date: Date(),
                                title: data.title,
                                artist: data.artist,
                                artworkData: data.artworkData,
                                isPlaying: data.isPlaying)
        
        // Refresh every 5 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Entry View
struct MusicPlayerWidgetEntryView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(title: entry.title,
                            artist: entry.artist,
                            artworkData: entry.artworkData,
                            isPlaying: entry.isPlaying)
        case .systemMedium:
            MediumWidgetView(title: entry.title,
                             artist: entry.artist,
                             artworkData: entry.artworkData,
                             isPlaying: entry.isPlaying)
        default:
            SmallWidgetView(title: entry.title,
                            artist: entry.artist,
                            artworkData: entry.artworkData,
                            isPlaying: entry.isPlaying)
        }
    }
}

// MARK: - Widget
struct MusicPlayerWidget: Widget {
    let kind: String = "MusicPlayerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MusicPlayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Naa Paata")
        .description("Your World. Your Sounds.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
