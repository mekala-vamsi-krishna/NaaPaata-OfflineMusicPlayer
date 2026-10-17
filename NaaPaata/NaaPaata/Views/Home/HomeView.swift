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
    @EnvironmentObject private var appearanceManager: AppearanceManager
    @EnvironmentObject private var folderService: DocumentFolderService
    @Environment(\.modelContext) private var modelContext

    @Query private var favourites: [FavouriteSong]

    private var accent: Color { .accentColor }

    // MARK: - Navigation state

    @State private var navigateToEqualizer = false

    // MARK: - Recents

    /// The most recently played songs, newest first. Recomputed on each
    /// render so the section stays live as the user plays tracks.
    private var recentSongs: [Song] {
        let service = SmartPlaylistService(
            context: modelContext,
            folderService: folderService
        )
        return service.compute(kind: .recents, from: libraryViewModel.songs)
    }

    /// Up to 10 cards shown inline. The "See All" link opens the full list.
    private var recentSongsPreview: [Song] {
        Array(recentSongs.prefix(10))
    }

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
                countText: favourites.isEmpty
                    ? "Your picks"
                    : "\(favourites.count) songs",
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
            VStack(alignment: .leading, spacing: 28) {

                // Recents — only shows when there's playback history.
                if !recentSongsPreview.isEmpty {
                    recentsSection
                }

                libraryGrid
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Home")
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

    // MARK: - Recents section

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Section header
            HStack {
                Text("Recents")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                NavigationLink(value: SmartPlaylistRoute(kind: .recents)) {
                    HStack(spacing: 2) {
                        Text("See All")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Horizontal card row
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(recentSongsPreview) { song in
                        RecentSongCard(
                            song: song,
                            isCurrentSong: libraryViewModel.currentSong?.id == song.id,
                            isPlaying: libraryViewModel.isPlaying
                        ) {
                            HapticManager.shared.light()
                            libraryViewModel.play(song, in: recentSongs)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Library grid

    private var libraryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Section header
            Text("Library")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(cards) { card in
                    cardView(card)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Library card

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

            Color(.secondarySystemGroupedBackground)

            Image(systemName: card.symbol)
                .font(.system(size: 110, weight: .ultraLight))
                .foregroundStyle(accent.opacity(0.10))
                .padding(.trailing, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: .bottomTrailing)

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
//
//  RecentSongCard.swift
//  NaaPaata
//

import SwiftUI
import UIKit

/// Compact card for a recently played song. Used in the horizontally
/// scrolling "Recents" row on the Home tab.
struct RecentSongCard: View {

    let song: Song
    let isCurrentSong: Bool
    let isPlaying: Bool
    let onPlay: () -> Void

    private let cardWidth: CGFloat = 140

    private var artworkImage: UIImage? {
        guard let data = song.artworkData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {

                artwork
                    .frame(width: cardWidth, height: cardWidth)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isCurrentSong ? Color.accentColor : .primary)
                        .lineLimit(1)

                    Text(song.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: cardWidth, alignment: .leading)
            }
        }
        .buttonStyle(RecentCardPressStyle())
        .accessibilityLabel("Play \(song.title) by \(song.artist)")
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack(alignment: .bottomTrailing) {

            // Base artwork
            Group {
                if let artworkImage {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.55),
                                Color.accentColor.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .frame(width: cardWidth, height: cardWidth)
            .clipped()

            // Play button or now-playing indicator
            playBadge
                .padding(8)
        }
    }

    @ViewBuilder
    private var playBadge: some View {
        if isCurrentSong {
            // Now playing — equalizer bars in a blurred circle
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 34, height: 34)

                EqualizerBars(
                    isPlaying: isPlaying,
                    size: 16,
                    barCount: 3,
                    color: .white
                )
            }
            .transition(.opacity.combined(with: .scale))
        } else {
            // Idle — play button
            ZStack {
                Circle()
                    .fill(.black.opacity(0.45))
                    .frame(width: 34, height: 34)

                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(x: 1)          // optical centering for the triangle
            }
        }
    }
}

// MARK: - Press style

private struct RecentCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.75),
                value: configuration.isPressed
            )
    }
}
