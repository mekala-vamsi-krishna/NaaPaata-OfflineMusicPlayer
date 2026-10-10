//
//  SearchView.swift
//  NaaPaata
//

import SwiftUI

struct SearchView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

    @State private var searchText = ""

    // MARK: - Filtered data

    private var matchedSongs: [Song] {
        guard !searchText.isEmpty else { return [] }
        return libraryViewModel.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var matchedAlbums: [Album] {
        guard !searchText.isEmpty else { return [] }

        return Dictionary(grouping: matchedSongs, by: \.album)
            .filter { !$0.key.isEmpty }
            .map { key, songs in
                Album(
                    id: key,
                    title: key,
                    artist: songs.first?.artist ?? "Unknown Artist",
                    songs: songs.sorted {
                        $0.title.localizedStandardCompare($1.title) == .orderedAscending
                    }
                )
            }
            .sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
    }

    private var hasResults: Bool {
        !matchedSongs.isEmpty || !matchedAlbums.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Group {
            if searchText.isEmpty {
                emptyPrompt
            } else if !hasResults {
                noResults
            } else {
                resultsList
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Songs, albums, artists…"
        )
    }

    // MARK: - Prompt states

    private var emptyPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("Search songs and albums")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("No results for “\(searchText)”")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {

                if !matchedSongs.isEmpty {
                    songsSection
                }

                if !matchedAlbums.isEmpty {
                    albumsSection
                }
            }
            .padding(.vertical, 8)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
        }
    }

    // MARK: - Songs section

    private var songsSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Songs")
                .font(.title3.weight(.bold))
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(matchedSongs) { song in
                    SongRowView(
                        song: song,
                        isCurrentSong: libraryViewModel.currentSong?.id == song.id
                    )
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        libraryViewModel.play(song, in: matchedSongs)
                    }

                    if song.id != matchedSongs.last?.id {
                        Divider().padding(.leading, 60)
                    }
                }
            }
        }
    }

    // MARK: - Albums section

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Albums")
                .font(.title3.weight(.bold))
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(matchedAlbums) { album in
                    NavigationLink(value: album) {
                        albumRow(album)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func albumRow(_ album: Album) -> some View {
        HStack(spacing: 14) {

            ArtworkView(data: album.artworkData, size: 50, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(album.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
