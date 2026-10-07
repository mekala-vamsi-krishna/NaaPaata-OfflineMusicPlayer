//
//  GenreDetailView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI

struct GenreDetailView: View {

    // MARK: - Dependencies

    let genre: Genre
    @ObservedObject var viewModel: MusicLibraryViewModel

    // MARK: - Local state

    @State private var songToAddToPlaylist: Song?
    @State private var infoSong: Song?

    // MARK: - Derived

    private var songs: [Song] {
        viewModel.genres.first { $0.id == genre.id }?.songs ?? genre.songs
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
        .navigationTitle(genre.name)
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
                Text(genre.name)
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
            if let image = genre.artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(white: 0.30),
                            Color(white: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "guitars")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 180, height: 180)
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .black.opacity(0.20), radius: 16, y: 8)
    }

    private var headerSubtitle: String {
        let songCount = songs.count
        let songLabel = "\(songCount) song\(songCount == 1 ? "" : "s")"

        let artists = Set(songs.map(\.artist)).count
        let artistLabel = "\(artists) artist\(artists == 1 ? "" : "s")"

        let duration = genre.totalDuration
        if duration > 0 {
            return "\(songLabel) · \(artistLabel) · \(genre.formattedTotalDuration)"
        }
        return "\(songLabel) · \(artistLabel)"
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
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                genreSongRow(song: song)
                    .padding(.horizontal, 20)

                if index < songs.count - 1 {
                    Divider()
                        .padding(.leading, 20 + 52 + 14)
                }
            }
        }
    }

    private func genreSongRow(song: Song) -> some View {
        let isCurrent = viewModel.currentSong?.id == song.id

        return HStack(spacing: 14) {

            Button {
                HapticManager.shared.light()
                viewModel.play(song, in: songs)
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
                            isPlaying: viewModel.isPlaying,
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
