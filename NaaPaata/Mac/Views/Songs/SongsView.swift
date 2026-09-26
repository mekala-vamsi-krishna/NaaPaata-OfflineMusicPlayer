//
//  SongsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct SongsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var router: AppRouter

    @ObservedObject var viewModel: MusicLibraryViewModel

    @State private var sortOption: SongSortOption = .titleAscending
    @AppStorage("songs.sortOption") private var storedSortRawValue = SongSortOption.titleAscending.rawValue
    
    @Query private var favourites: [FavouriteSong]

    private var displayedSongs: [Song] {
        viewModel.songs.sorted(by: sortOption.areInIncreasingOrder)
    }
    
    private var favouritePaths: Set<String> {
        Set(favourites.map(\.songPath))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.songs.isEmpty {
                ProgressView("Scanning library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.songs.isEmpty {
                EmptyStateView(
                    title: "No Songs Yet",
                    systemImage: "music.note",
                    message: "Add audio files to ~/Music/Naa Paata to see them here.",
                    actionTitle: "Open Library Folder",
                    action: viewModel.revealLibraryInFinder
                )
            } else {
                songList
            }
        }
        .navigationTitle("Songs")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onAppear {
            sortOption = SongSortOption(rawValue: storedSortRawValue) ?? .titleAscending
        }
        .onChange(of: sortOption) { _, newValue in
            storedSortRawValue = newValue.rawValue
        }
    }

    // MARK: - List

    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(displayedSongs) { song in
                    SongRowView(
                        song: song,
                        isCurrentSong: viewModel.currentSong?.id == song.id,
                        isPlaying: viewModel.isPlaying,
                        isFavourite: favouritePaths.contains(song.url.path),
                        onSelect: { viewModel.play($0, in: displayedSongs) },
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

    // MARK: - Header (Play All / Shuffle All / Sort)

    private var headerBar: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.playAll(displayedSongs)
            } label: {
                Label("Play All", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                viewModel.shuffleAll(displayedSongs)
            } label: {
                Label("Shuffle All", systemImage: "shuffle")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.isLoading)

            Spacer()

            sortMenu
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

    // MARK: - Sort menu

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                ForEach(SongSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sort songs")
    }
}
