//
//  HomeView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI
import SwiftData

struct LibraryCard: Identifiable {
    let id: String
    let title: String
    let countText: String
    let symbol: String
    let route: LibraryRoute?
}

struct HomeView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    @Query private var favourites: [FavouriteSong]

    private var accent: Color { themeManager.accent }

    // MARK: - Navigation state

    @State private var navigateToEqualizer = false

    // MARK: - Card data

    private var cards: [LibraryCard] {
        [
            LibraryCard(
                id: "songs",
                title: "Songs",
                countText: "\(libraryViewModel.songs.count) songs",
                symbol: "music.note",
                route: .songs
            ),
            LibraryCard(
                id: "albums",
                title: "Albums",
                countText: "\(libraryViewModel.albums.count) albums",
                symbol: "square.stack",
                route: .albums
            ),
            LibraryCard(
                id: "artists",
                title: "Artists",
                countText: "\(libraryViewModel.artists.count) artists",
                symbol: "music.mic",
                route: .artists
            ),
            LibraryCard(
                id: "genres",
                title: "Genres",
                countText: "\(libraryViewModel.genres.count) genres",
                symbol: "guitars",
                route: .genres
            ),
            LibraryCard(
                id: "favourites",
                title: "Favourites",
                countText: "Your picks",
                symbol: "heart.fill",
                route: .favourites
            )
        ]
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(cards) { card in
                    cardView(card)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .navigationDestination(isPresented: $navigateToEqualizer) {
            EqualizerView()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                navigateToEqualizer = true
            } label: {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("Equalizer")
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func cardView(_ card: LibraryCard) -> some View {
        if let route = card.route {
            NavigationLink(value: route) {
                cardContent(card)
            }
            .buttonStyle(CardButtonStyle())
        } else {
            cardContent(card)
        }
    }

    private func cardContent(_ card: LibraryCard) -> some View {
        ZStack(alignment: .topLeading) {

            // Plain adaptive background
            Color(.secondarySystemGroupedBackground)

            // Faint watermark symbol, anchored bottom-right
            Image(systemName: card.symbol)
                .font(.system(size: 110, weight: .ultraLight))
                .foregroundStyle(accent.opacity(0.10))
                .padding(.trailing, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: .bottomTrailing)

            // Title + count
            VStack(alignment: .leading, spacing: 5) {
                Text(card.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(card.countText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            // Small symbol accent, bottom-right
            Image(systemName: card.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .padding(.trailing, 18)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: .bottomTrailing)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - Press animation

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
