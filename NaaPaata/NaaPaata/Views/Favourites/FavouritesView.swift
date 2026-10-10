//
//  FavouritesView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI
import SwiftData

struct FavouritesView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var folderService: DocumentFolderService

    @Query(sort: \FavouriteSong.dateAdded, order: .reverse)
    private var favourites: [FavouriteSong]

    @State private var searchText = ""

    // MARK: - Derived

    private var resolvedSongs: [Song] {
        let paths = favourites.map(\.songRelativePath)
        return libraryViewModel.songs(
            forRelativePaths: paths,
            folderService: folderService
        )
    }

    private var displayedSongs: [Song] {
        guard !searchText.isEmpty else { return resolvedSongs }
        return resolvedSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if favourites.isEmpty {
                emptyState
            } else if displayedSongs.isEmpty {
                noSearchResults
            } else {
                content
            }
        }
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search favourites"
        )
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {

                actionButtons

                songList
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton(
                title: "Play",
                icon: "play.fill",
                isPrimary: true,
                action: {
                    guard !displayedSongs.isEmpty else { return }
                    HapticManager.shared.medium()
                    libraryViewModel.playAll(displayedSongs)
                }
            )
            .disabled(displayedSongs.isEmpty)
            .opacity(displayedSongs.isEmpty ? 0.5 : 1)

            actionButton(
                title: "Shuffle",
                icon: "shuffle",
                isPrimary: false,
                action: {
                    guard !displayedSongs.isEmpty else { return }
                    HapticManager.shared.medium()
                    libraryViewModel.shuffleAll(displayedSongs)
                }
            )
            .disabled(displayedSongs.isEmpty)
            .opacity(displayedSongs.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
    }

    private func actionButton(
        title: String,
        icon: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isPrimary ? .white : Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                Group {
                    if isPrimary {
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.accentColor.opacity(0.12)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                !isPrimary
                    ? Capsule().strokeBorder(
                        Color.accentColor.opacity(0.35),
                        lineWidth: 1
                    )
                    : nil
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Song list

    private var songList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(displayedSongs.enumerated()), id: \.element.id) { index, song in
                favouriteSongRow(song: song)
                    .padding(.horizontal, 20)

                if index < displayedSongs.count - 1 {
                    Divider()
                        .padding(.leading, 20 + 52 + 14)
                }
            }
        }
    }

    private func favouriteSongRow(song: Song) -> some View {
        let isCurrent = libraryViewModel.currentSong?.id == song.id

        return HStack(spacing: 14) {

            Button {
                HapticManager.shared.light()
                libraryViewModel.play(song, in: displayedSongs)
            } label: {
                HStack(spacing: 14) {

                    artworkThumb(song: song)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isCurrent ? Color.accentColor : .primary)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if isCurrent {
                        EqualizerBars(
                            isPlaying: libraryViewModel.isPlaying,
                            size: 18,
                            barCount: 3,
                            color: .accentColor
                        )
                        .transition(.opacity.combined(with: .scale))
                    }

                    if let duration = song.duration {
                        Text(formattedDuration(duration))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isCurrent)

            // Unfavourite via the heart button — tap to remove.
            Button {
                HapticManager.shared.light()
                unfavourite(song)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func artworkThumb(song: Song) -> some View {
        Group {
            if let data = song.artworkData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.secondary.opacity(0.15)
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Empty states

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Favourites Yet", systemImage: "heart")
        } description: {
            Text("Tap the heart on any song to save it here.")
        }
    }

    private var noSearchResults: some View {
        ContentUnavailableView.search(text: searchText)
    }

    // MARK: - Actions

    private func unfavourite(_ song: Song) {
        guard let relativePath = folderService.relativePath(for: song.url) else {
            return
        }
        let service = FavouritesService(context: modelContext)
        try? service.removeFavourite(relativePath)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    
}
