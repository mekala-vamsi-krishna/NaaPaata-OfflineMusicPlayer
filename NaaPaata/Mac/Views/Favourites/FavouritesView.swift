//
//  FavouritesView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/17/26.
//

import SwiftUI
import SwiftData

struct FavouritesView: View {

    @EnvironmentObject private var router: AppRouter
    
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var viewModel: MusicLibraryViewModel

    /// Sorted newest first — the order in which the user favourited them.
    @Query(sort: \FavouriteSong.dateAdded, order: .reverse)
    private var favourites: [FavouriteSong]

    /// Resolve favourited paths against the live library. Songs whose files
    /// no longer exist are silently skipped.
    private var songs: [Song] {
        let pathSet = Set(favourites.map(\.songPath))
        return viewModel.songs.filter { pathSet.contains($0.url.path) }
    }

    var body: some View {
        Group {
            if songs.isEmpty {
                EmptyStateView(
                    title: "No Favourites Yet",
                    systemImage: "heart",
                    message: "Tap the heart while a song is playing to add it here."
                )
            } else {
                songList
            }
        }
        .navigationTitle("Favourites")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }

    // MARK: - List

    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(songs) { song in
                    SongRowView(
                        song: song,
                        isCurrentSong: viewModel.currentSong?.id == song.id,
                        isPlaying: viewModel.isPlaying,
                        isFavourite: true,
                        onSelect: { viewModel.play($0, in: songs) },
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
            .padding(.vertical, 6)
        }
        .safeAreaInset(edge: .top, spacing: 0) { headerBar }
    }

    // MARK: - Header (Play All / Shuffle All)

    private var headerBar: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.playAll(songs)
            } label: {
                Label("Play All", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .help("Play all favourites")

            Button {
                viewModel.shuffleAll(songs)
            } label: {
                Label("Shuffle All", systemImage: "shuffle")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .help("Shuffle all favourites")

            Spacer()

            Text("\(songs.count) song\(songs.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 1)
        }
    }
}
