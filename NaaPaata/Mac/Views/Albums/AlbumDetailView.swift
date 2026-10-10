//
//  AlbumDetailView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct AlbumDetailView: View {

    let album: Album
    
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(24)

                trackList
            }
        }
        .navigationTitle(album.title)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            ArtworkView(data: album.artworkData, size: 200, cornerRadius: 12)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                Text(album.title)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(2)

                Text(album.artist)
                    .font(.title3)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    Button {
                        viewModel.playAll(album.songs)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        viewModel.shuffleAll(album.songs)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var subtitleText: String {
        let count = album.trackCount
        let duration = Self.formatTotalDuration(album.totalDuration)
        return "\(count) song\(count == 1 ? "" : "s") • \(duration)"
    }

    // MARK: - Track list

    private var trackList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

            ForEach(Array(album.songs.enumerated()), id: \.element.id) { index, song in
                AlbumTrackRowView(
                    trackNumber: index + 1,
                    song: song,
                    isCurrentSong: viewModel.currentSong?.id == song.id,
                    isPlaying: viewModel.isPlaying,
                    onSelect: { viewModel.play($0, in: album.songs) },
                    onPlayNext: viewModel.enqueueNext,
                    onDelete: { viewModel.deleteSong($0, in: modelContext) },
                )
            }
        }
    }

    // MARK: - Helpers

    private static func formatTotalDuration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "--" }
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0
            ? "\(hours) hr \(minutes) min"
            : "\(minutes) min"
    }
}
