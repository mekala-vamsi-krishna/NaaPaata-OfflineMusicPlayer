//
//  GenreDetailView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import SwiftUI
import SwiftData
import AppKit

struct GenreDetailView: View {

    let genre: Genre
    @ObservedObject var viewModel: MusicLibraryViewModel
    @ObservedObject var router: AppRouter

    @Environment(\.modelContext) private var modelContext
    @Query private var favourites: [FavouriteSong]

    private var favouritePaths: Set<String> {
        Set(favourites.map(\.songPath))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(24)

                trackList
            }
        }
        .navigationTitle(genre.name)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            artwork

            VStack(alignment: .leading, spacing: 10) {
                Text(genre.name)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(2)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    Button {
                        viewModel.playAll(genre.songs)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        viewModel.shuffleAll(genre.songs)
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

    private var artwork: some View {
        ZStack {
            if let data = genre.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                    Image(systemName: "guitars")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    private var subtitleText: String {
        let count = genre.songCount
        let duration = Self.formatTotalDuration(
            genre.songs.compactMap(\.duration).reduce(0, +)
        )
        return "\(count) song\(count == 1 ? "" : "s") • \(duration)"
    }

    // MARK: - Track list

    private var trackList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

            ForEach(genre.songs) { song in
                SongRowView(
                    song: song,
                    isCurrentSong: viewModel.currentSong?.id == song.id,
                    isPlaying: viewModel.isPlaying,
                    isFavourite: favouritePaths.contains(song.url.path),
                    onSelect: { viewModel.play($0, in: genre.songs) },
                    onDelete: { viewModel.deleteSong($0, in: modelContext) },
                    onPlayNext: viewModel.enqueueNext,
                    onGoToAlbum: { song in
                        if let album = viewModel.album(for: song) {
                            router.push(album)
                        }
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
        return hours > 0
            ? "\(hours) hr \(minutes) min"
            : "\(minutes) min"
    }
}
