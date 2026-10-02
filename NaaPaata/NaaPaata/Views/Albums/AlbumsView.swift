//
//  AlbumsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

struct AlbumsView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

    @State private var searchText = ""
    @State private var sortOption: AlbumSortOption = .titleAscending
    @AppStorage("albums.sortOption") private var storedSortRawValue = AlbumSortOption.titleAscending.rawValue

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]

    private var displayedAlbums: [Album] {
        let sorted = libraryViewModel.albums.sorted(
            by: sortOption.areInIncreasingOrder
        )
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if libraryViewModel.isLoading && libraryViewModel.albums.isEmpty {
                ProgressView("Scanning library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if libraryViewModel.albums.isEmpty {
                emptyState

            } else {
                albumGrid
            }
        }
        .navigationTitle("Albums")
        .toolbar { toolbarContent }
        .onAppear {
            sortOption = AlbumSortOption(rawValue: storedSortRawValue) ?? .titleAscending
        }
        .onChange(of: sortOption) { _, newValue in
            storedSortRawValue = newValue.rawValue
        }
    }

    // MARK: - Grid

    private var albumGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(displayedAlbums) { album in
                    NavigationLink(value: album) {
                        AlbumCardView(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort By", selection: $sortOption) {
                    ForEach(AlbumSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Albums Yet")
                .font(.title3.weight(.semibold))

            Text("Albums are created automatically from your songs' album metadata.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
