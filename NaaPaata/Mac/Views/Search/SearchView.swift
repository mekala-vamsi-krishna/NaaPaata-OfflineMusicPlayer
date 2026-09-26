//
//  SearchView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/14/26.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var router: AppRouter

    @ObservedObject var viewModel: MusicLibraryViewModel

    @State private var scope: SearchScope = .songs
    @State private var searchText = ""

    var body: some View {

        VStack(spacing: 0) {

            header

            Divider()

            results
        }
        .navigationTitle("Search")
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album, viewModel: viewModel)
        }
    }

    // MARK: - Header (search field + scope pills, side by side)

    private var header: some View {

        HStack(spacing: 16) {

            searchField

            scopePicker

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColor.surface)
    }

    // MARK: - Search field

    private var searchField: some View {

        HStack(spacing: 8) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)

            TextField(scope.placeholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textPrimary)

            if !searchText.isEmpty {

                Button {

                    searchText = ""

                } label: {

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minWidth: 160, maxWidth: 280)
        .background(
            Capsule().fill(AppColor.background)
        )
        .overlay(
            Capsule().strokeBorder(AppColor.border)
        )
    }

    // MARK: - Scope pills

    private var scopePicker: some View {

        HStack(spacing: 6) {

            ForEach(SearchScope.allCases) { s in

                scopePill(s)
            }
        }
    }

    private func scopePill(_ s: SearchScope) -> some View {

        let isSelected = s == scope

        return Button {

            withAnimation(.easeInOut(duration: 0.15)) {
                scope = s
            }

        } label: {

            Text(s.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(
                    isSelected
                        ? AppColor.textPrimary
                        : AppColor.textSecondary
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? AppColor.border
                                : Color.clear
                        )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {

        switch scope {

        case .songs:
            songsResults

        case .albums:
            albumsResults

        case .playlists:
            playlistsResults
        }
    }

    // MARK: - Filtered data

    private var filteredSongs: [Song] {

        guard !searchText.isEmpty else { return [] }

        return viewModel.songs.filter {

            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredAlbums: [Album] {

        guard !searchText.isEmpty else { return [] }

        return viewModel.albums.filter {

            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Songs results

    @ViewBuilder
    private var songsResults: some View {

        if searchText.isEmpty {

            emptyState(
                icon: "music.note",
                message: "Search your library for songs."
            )

        } else if filteredSongs.isEmpty {

            emptyState(
                icon: "magnifyingglass",
                message: "No songs match “\(searchText)”."
            )

        } else {

            List(filteredSongs) { song in

                SongRowView(
                    song: song,
                    isCurrentSong: viewModel.currentSong?.id == song.id,
                    isPlaying: viewModel.isPlaying,
                    onSelect: { viewModel.play($0, in: filteredSongs) },
                    onDelete: { viewModel.deleteSong($0, in: modelContext) },
                    onPlayNext: viewModel.enqueueNext,
                    onGoToAlbum: { song in
                        if let album = viewModel.album(for: song) {
                            router.push(album)
                        }
                    }
                )
            }
            .listStyle(.inset)
        }
    }

    // MARK: - Albums results

    @ViewBuilder
    private var albumsResults: some View {

        if searchText.isEmpty {

            emptyState(
                icon: "square.stack",
                message: "Search your library for albums."
            )

        } else if filteredAlbums.isEmpty {

            emptyState(
                icon: "magnifyingglass",
                message: "No albums match “\(searchText)”."
            )

        } else {

            ScrollView {

                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: 170, maximum: 220),
                            spacing: 22
                        )
                    ],
                    spacing: 24
                ) {

                    ForEach(filteredAlbums) { album in

                        NavigationLink(value: album) {

                            AlbumCardView(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(22)
            }
        }
    }

    // MARK: - Playlists results

    @ViewBuilder
    private var playlistsResults: some View {

        emptyState(
            icon: "music.note.list",
            message: searchText.isEmpty
                ? "Search your library for playlists."
                : "No playlists match “\(searchText)”."
        )
    }

    // MARK: - Empty state

    private func emptyState(icon: String, message: String) -> some View {

        VStack(spacing: 12) {

            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppColor.textTertiary)

            Text(message)
                .font(.callout)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
