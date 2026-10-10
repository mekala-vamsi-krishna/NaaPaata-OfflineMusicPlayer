//
//  GenresView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import SwiftUI

struct GenresView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    private let targetCardWidth: CGFloat = 240

    private let gridSpacing: CGFloat = 20

    private let gridPadding: CGFloat = 22

    var body: some View {
        Group {
            if viewModel.genres.isEmpty {
                EmptyStateView(
                    title: "No Genres Yet",
                    systemImage: "guitars",
                    message: "Add audio files with genre metadata to see them here.",
                    actionTitle: "Open Library Folder",
                    action: viewModel.revealLibraryInFinder
                )
            } else {
                grid
            }
        }
        .navigationTitle("Genres")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }

    // MARK: - Grid

    private var grid: some View {
        GeometryReader { geo in
            let layout = layout(for: geo.size.width)

            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: gridSpacing),
                        count: layout.columns
                    ),
                    alignment: .leading,
                    spacing: gridSpacing
                ) {
                    ForEach(viewModel.genres) { genre in
                        NavigationLink(value: genre) {
                            GenreCardView(genre: genre, width: layout.cardWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(gridPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Layout computation
    private func layout(for availableWidth: CGFloat) -> (columns: Int, cardWidth: CGFloat) {
        let usable = availableWidth - gridPadding * 2

        guard usable > 0 else {
            return (1, max(targetCardWidth, 1))
        }
        
        var columns = 2
        while true {
            let next = columns + 1
            let widthForNext = (usable - CGFloat(next - 1) * gridSpacing) / CGFloat(next)
            if widthForNext < targetCardWidth { break }
            columns = next
        }

        let cardWidth = (usable - CGFloat(columns - 1) * gridSpacing) / CGFloat(columns)
        return (columns, cardWidth)
    }
}
