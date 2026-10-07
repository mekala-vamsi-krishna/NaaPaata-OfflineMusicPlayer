//
//  ArtistDetailView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI
import UIKit

struct ArtistDetailView: View {

    // MARK: - Dependencies

    let artist: Artist
    @ObservedObject var viewModel: MusicLibraryViewModel

    // MARK: - Local state

    @State private var songToAddToPlaylist: Song?
    @State private var infoSong: Song?

    // MARK: - Derived

    /// Live view of the artist's songs. If the user deletes a song
    /// elsewhere in the app, this reflects the change immediately.
    private var songs: [Song] {
        viewModel.artist(named: artist.name)?.songs ?? artist.songs
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                actionButtons
                songList
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $infoSong) { song in
            SongInfoView(song: song)
        }
        .sheet(item: $songToAddToPlaylist) { song in
            AddToPlaylistView(song: song)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {

            artworkHero

            VStack(spacing: 6) {
                Text(artist.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)

                Text(headerSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var artworkHero: some View {
        Group {
            if let image = artist.artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.40),
                            Color.accentColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "music.mic")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 180, height: 180)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }

    private var headerSubtitle: String {
        let count = songs.count
        let countText = count == 1 ? "1 song" : "\(count) songs"

        if artist.totalDuration > 0 {
            return "\(countText) · \(artist.formattedTotalDuration)"
        }
        return countText
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton(
                title: "Play",
                icon: "play.fill",
                isPrimary: true,
                action: {
                    guard !songs.isEmpty else { return }
                    HapticManager.shared.medium()
                    viewModel.playAll(songs)
                }
            )
            .disabled(songs.isEmpty)
            .opacity(songs.isEmpty ? 0.5 : 1)

            actionButton(
                title: "Shuffle",
                icon: "shuffle",
                isPrimary: false,
                action: {
                    guard !songs.isEmpty else { return }
                    HapticManager.shared.medium()
                    viewModel.shuffleAll(songs)
                }
            )
            .disabled(songs.isEmpty)
            .opacity(songs.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Action button helper

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
                        // Soft accent tint instead of `.ultraThinMaterial`,
                        // which reads as disabled on light mode.
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
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                artistSongRow(song: song)
                    .padding(.horizontal, 20)

                if index < songs.count - 1 {
                    Divider()
                        .padding(.leading, 20 + 52 + 14)
                }
            }
        }
    }

    // MARK: - Song row

    private func artistSongRow(song: Song) -> some View {
        HStack(spacing: 14) {

            // Tappable play area: artwork + metadata
            Button {
                HapticManager.shared.light()
                viewModel.play(song, in: songs)
            } label: {
                HStack(spacing: 14) {

                    artworkThumb(song: song)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(
                                viewModel.currentSong?.id == song.id
                                ? Color.accentColor
                                : .primary
                            )
                            .lineLimit(1)

                        Text(song.album)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if let duration = song.duration {
                        Text(formattedDuration(duration))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Menu: separate button, iOS-native Menu UI
            Menu {
                Button {
                    viewModel.enqueueNext(song)
                } label: {
                    Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                }

                Button {
                    songToAddToPlaylist = song
                } label: {
                    Label("Add to Playlist", systemImage: "music.note.list")
                }

                Divider()

                Button {
                    infoSong = song
                } label: {
                    Label("Song Info", systemImage: "info.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
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

    // MARK: - Helpers

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
