//
//  SongsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

struct SongsView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject private var viewModel: MusicLibraryViewModel

    @State private var sortOption: SongSortOption = .titleAscending
    @AppStorage("songs.sortOption") private var storedSortRawValue = SongSortOption.titleAscending.rawValue

    @State private var navigateToEqualizer = false

    private var displayedSongs: [Song] {
        viewModel.songs.sorted(by: sortOption.areInIncreasingOrder)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.songs.isEmpty {
                ProgressView("Scanning library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if viewModel.songs.isEmpty {
                emptyState

            } else {
                songList
            }
        }
        .navigationTitle("Songs")
        .toolbar { toolbarContent }
        .navigationDestination(isPresented: $navigateToEqualizer) {
            EqualizerView()
        }
        .onAppear {
            sortOption = SongSortOption(rawValue: storedSortRawValue) ?? .titleAscending
        }
        .onChange(of: sortOption) { _, newValue in
            storedSortRawValue = newValue.rawValue
        }
        .task {
            if viewModel.songs.isEmpty {
                await viewModel.loadLibrary()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await viewModel.syncLibrary()
                }
            }
        }
    }

    // MARK: - List

    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {

                SongsTopBar(
                    count: displayedSongs.count,
                    sortOption: $sortOption,
                    onPlayAll: {
                        viewModel.playAll(displayedSongs)
                    },
                    onShuffleAll: {
                        viewModel.shuffleAll(displayedSongs)
                    }
                )

                ForEach(displayedSongs) { song in
                    SongRowView(
                        song: song,
                        isCurrentSong: viewModel.currentSong?.id == song.id
                    )
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.play(song, in: displayedSongs)
                    }
                }

                Color.clear.frame(height: 40)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                navigateToEqualizer = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("Equalizer")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Songs Yet")
                .font(.title3.weight(.semibold))

            Text("Add audio files to the NaaPaata folder in the Files app.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
