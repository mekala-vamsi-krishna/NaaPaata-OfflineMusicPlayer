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
    @State private var showHelpSheet = false

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
        .sheet(isPresented: $showHelpSheet) {
            UploadHelpSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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
        VStack(spacing: 16) {
            Image(systemName: "guitars")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Genres Yet")
                .font(.title3.weight(.semibold))

            Text("Genres are created automatically from your songs' genre metadata.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            
            // Help Button
            Button {
                showHelpSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("How to upload songs?")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
