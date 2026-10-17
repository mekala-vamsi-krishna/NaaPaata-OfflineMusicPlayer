//
//  AlbumDetailView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/21/25.
//

import SwiftUI

struct AlbumDetailView: View {

    let album: Album

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

    // MARK: - Derived

    private var sortedSongs: [Song] {
        album.songs.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private var totalDuration: TimeInterval {
        sortedSongs.compactMap(\.duration).reduce(0, +)
    }

    /// Height of the full-bleed artwork header.
    private let headerHeight: CGFloat = 480

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                contentSection
                    .padding(.top, 20)
                    .padding(.bottom, 120)
            }
            // ✅ Keep the outer stack pinned to screen width so the header
            //    and the list share the same coordinate system.
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottom) {

            // ✅ Artwork background — pinned via Color.clear so the
            //    scaledToFill image can overflow without expanding the
            //    parent's layout width. This is what stops the info text
            //    from being pushed off the leading edge.
            Color.clear
                .frame(height: headerHeight)
                .overlay {
                    artworkLayer
                }
                .clipped()

            // Gradient fade into the system background
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .clear, location: 0.45),
                    .init(color: Color(.systemBackground).opacity(0.55), location: 0.70),
                    .init(color: Color(.systemBackground).opacity(0.90), location: 0.88),
                    .init(color: Color(.systemBackground), location: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Album info at bottom of the header
            VStack(alignment: .leading, spacing: 6) {
                Text(album.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(album.artist)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text("\(sortedSongs.count) song\(sortedSongs.count == 1 ? "" : "s") • \(formatTime(totalDuration))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: headerHeight)
        .clipped()
    }

    // MARK: - Artwork Layer (used inside the overlay)

    @ViewBuilder
    private var artworkLayer: some View {
        if let data = album.artworkData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.65),
                    Color.accentColor.opacity(0.15),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 84, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(spacing: 20) {
            actionButtons
            songList
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {

            Button {
                libraryViewModel.playAll(sortedSongs)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Play All")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    Capsule().fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)

            Button {
                libraryViewModel.shuffleAll(sortedSongs)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Shuffle")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    Capsule().fill(Color.accentColor.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Song list

    private var songList: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedSongs.enumerated()), id: \.element.id) { index, song in

                albumSongRow(song: song)

                if index < sortedSongs.count - 1 {
                    Divider()
                        .padding(.leading, 24 + 48 + 14)
                }
            }
        }
    }

    private func albumSongRow(song: Song) -> some View {
        let isCurrent = libraryViewModel.currentSong?.id == song.id

        return Button {
            libraryViewModel.play(song, in: sortedSongs)
        } label: {
            HStack(spacing: 14) {

                ArtworkView(
                    data: song.artworkData,
                    size: 48,
                    cornerRadius: 8
                )
                .overlay {
                    if isCurrent {
                        ZStack {
                            Color.black.opacity(0.55)
                            EqualizerBars(
                                isPlaying: libraryViewModel.isPlaying,
                                size: 16,
                                barCount: 3,
                                color: .white
                            )
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    }
                }

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

                Text(formatDuration(song.duration ?? 0))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins)m \(secs)s"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
