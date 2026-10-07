//
//  AlbumDetailsView.swift
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

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                header

                actionButtons

                songList
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
            }
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {

            ArtworkView(data: album.artworkData, size: 200, cornerRadius: 24)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)

            Text(album.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 24)

            Text("\(sortedSongs.count) song\(sortedSongs.count == 1 ? "" : "s") • \(formatTime(totalDuration))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            actionButton(title: "Play All", icon: "play.fill", isPrimary: true) {
                libraryViewModel.playAll(sortedSongs)
            }

            actionButton(title: "Shuffle", icon: "shuffle", isPrimary: false) {
                libraryViewModel.shuffleAll(sortedSongs)
            }
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
        VStack(spacing: 0) {
            ForEach(Array(sortedSongs.enumerated()), id: \.element.id) { index, song in

                HStack(spacing: 12) {

                    Text("\(index + 1)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .trailing)

                    SongRowView(
                        song: song,
                        isCurrentSong: libraryViewModel.currentSong?.id == song.id
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    libraryViewModel.play(song, in: sortedSongs)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins)m \(secs)s"
    }
}
