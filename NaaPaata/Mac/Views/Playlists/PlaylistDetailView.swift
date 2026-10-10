//
//  PlaylistDetailView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI
import SwiftData
import AppKit

struct PlaylistDetailView: View {

    let playlist: Playlist
    @ObservedObject var viewModel: MusicLibraryViewModel
    @ObservedObject var router: AppRouter

    @Environment(\.modelContext) private var modelContext

    private var songs: [Song] {
        playlist.songPaths.compactMap { path in
            viewModel.songs.first { $0.url.path == path }
        }
    }

    private var totalDuration: TimeInterval {
        songs.compactMap(\.duration).reduce(0, +)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(24)

                if songs.isEmpty {
                    emptySongs
                        .padding(24)
                } else {
                    trackList
                }
            }
        }
        .navigationTitle(playlist.name)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            artwork

            VStack(alignment: .leading, spacing: 10) {
                Text(playlist.name)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(2)

                if !playlist.descr.isEmpty {
                    Text(playlist.descr)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(3)
                }

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    Button {
                        viewModel.playAll(songs)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(songs.isEmpty)

                    Button {
                        viewModel.shuffleAll(songs)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(songs.isEmpty)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var artwork: some View {
        ZStack {
            if let data = playlist.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    private var subtitleText: String {
        let count = songs.count
        let duration = Self.formatTotalDuration(totalDuration)
        return "\(count) song\(count == 1 ? "" : "s") • \(duration)"
    }

    // MARK: - Empty state

    private var emptySongs: some View {
        VStack(spacing: 14) {
            Divider()

            VStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppColor.textTertiary)

                Text("No Songs in This Playlist")
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Right-click a song in your library to add it here.")
                    .font(.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    // MARK: - Track list

    private var trackList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                PlaylistSongRowView(
                    trackNumber: index + 1,
                    song: song,
                    isCurrentSong: viewModel.currentSong?.id == song.id,
                    isPlaying: viewModel.isPlaying,
                    onSelect: { viewModel.play($0, in: songs) },
                    onPlayNext: viewModel.enqueueNext,
                    onGoToAlbum: { song in
                        if let album = viewModel.album(for: song) {
                            router.push(album)
                        }
                    },
                    onRemoveFromPlaylist: { song in
                        try? PlaylistService(context: modelContext)
                            .removeSong(song.url, from: playlist)
                    }
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

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}
