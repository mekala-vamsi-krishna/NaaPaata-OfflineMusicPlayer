//
//  GenresView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//
//
//  GenresView.swift
//  NaaPaata
//

import SwiftUI

struct GenresView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)
    ]

    private var displayedGenres: [Genre] {
        guard !searchText.isEmpty else { return libraryViewModel.genres }
        return libraryViewModel.genres.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if libraryViewModel.isLoading && libraryViewModel.genres.isEmpty {
                ProgressView("Scanning library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if libraryViewModel.genres.isEmpty {
                emptyState

            } else {
                genreGrid
            }
        }
        .navigationTitle("Genres")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search genres"
        )
    }

    // MARK: - Grid

    private var genreGrid: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = 20
            let spacing: CGFloat = 16

            // Compute how many columns fit, then the exact width of each.
            let availableWidth = geo.size.width - horizontalPadding * 2
            let columnsCount = max(Int((availableWidth + spacing) / (160 + spacing)), 1)
            let cardWidth = (availableWidth - spacing * CGFloat(columnsCount - 1))
                            / CGFloat(columnsCount)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(displayedGenres) { genre in
                        NavigationLink(value: genre) {
                            GenreCardView(genre: genre, width: cardWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Genres Yet", systemImage: "guitars")
        } description: {
            Text("Genres are created automatically from your songs' genre metadata.")
        }
    }
}
