//
//  MusicPlayerWidget.swift
//  NaaPaata
//

import WidgetKit
import SwiftUI
import AppIntents

struct WidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let artworkData: Data?
    let isPlaying: Bool
}

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            title: "Song Title",
            artist: "Artist",
            artworkData: nil,
            isPlaying: false
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (WidgetEntry) -> Void
    ) {
        completion(makeEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<WidgetEntry>) -> Void
    ) {
        let entry = makeEntry()

        // Refresh every 15 minutes as a fallback. The app also calls
        // `reloadTimelines` on every state change, which is the primary
        // refresh path. This policy just covers the case where the app
        // is killed and the widget keeps showing stale state.
        let next = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: Date()
        ) ?? Date().addingTimeInterval(900)

        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> WidgetEntry {
        let data = SharedDataManager.shared.getWidgetData()

        return WidgetEntry(
            date: Date(),
            title: data.title ?? "No Song Playing",
            artist: data.artist ?? "",
            artworkData: data.artworkData,
            isPlaying: data.isPlaying
        )
    }
}

struct MusicPlayerWidgetEntryView: View {

    let entry: WidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(
                title: entry.title,
                artist: entry.artist,
                artworkData: entry.artworkData,
                isPlaying: entry.isPlaying
            )

        default:
            SmallWidgetView(
                title: entry.title,
                artist: entry.artist,
                artworkData: entry.artworkData,
                isPlaying: entry.isPlaying
            )
        }
    }
}

struct MusicPlayerWidget: Widget {

    let kind = "MusicPlayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            MusicPlayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Naa Paata")
        .description("Your World. Your Sounds.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
