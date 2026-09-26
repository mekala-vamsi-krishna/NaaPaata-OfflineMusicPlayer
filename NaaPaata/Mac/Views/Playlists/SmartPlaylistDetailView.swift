//
//  SmartPlaylistDetailView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct SmartPlaylistDetailView: View {

    let kind: SmartPlaylistKind
    @ObservedObject var viewModel: MusicLibraryViewModel

    private var songs: [Song] {
        Self.resolve(kind: kind, library: viewModel.songs)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(24)

                if songs.isEmpty {
                    emptyState
                        .padding(24)
                } else {
                    trackList
                }
            }
        }
        .navigationTitle(kind.title)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            artwork

            VStack(alignment: .leading, spacing: 10) {
                Text(kind.title)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(2)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    Button {
                        viewModel.playAll(songs)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(songs.isEmpty)

                    Button {
                        viewModel.shuffleAll(songs)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(songs.isEmpty)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var artwork: some View {
        ZStack(alignment: .topLeading) {
            kind.gradient

            Text(kind.title)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Image(systemName: kind.systemImage)
                .font(.system(size: 72, weight: .black))
                .foregroundStyle(.white.opacity(0.35))
                .rotationEffect(.degrees(15))
                .padding(.trailing, 20)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColor.primary.opacity(0.35), radius: 16, y: 8)
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private var subtitleText: String {
        let count = songs.count
        return "\(count) song\(count == 1 ? "" : "s")"
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Divider()

            VStack(spacing: 10) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppColor.textTertiary)

                Text(emptyMessage)
                    .font(.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    private var emptyMessage: String {
        switch kind {
        case .recents:
            return "Play some songs to see your recent activity here."
        case .mostlyPlayed:
            return "Your most played songs will appear here."
        case .neverPlayed:
            return "Every song in your library has been played at least once."
        }
    }

    // MARK: - Track list

    private var trackList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                PlaylistSongRowView(
                    trackNumber: index + 1,
                    song: song,
                    isCurrentSong: viewModel.currentSong?.id == song.id,
                    isPlaying: viewModel.isPlaying,
                    onSelect: { viewModel.play($0, in: songs) },
                    onPlayNext: viewModel.enqueueNext,
                    onGoToAlbum: { _ in },
                    onRemoveFromPlaylist: { _ in }
                )
            }
        }
    }

    // MARK: - Resolver

    static func resolve(kind: SmartPlaylistKind, library: [Song]) -> [Song] {
        let entries = PlayHistoryStore.shared.allEntries()
        let entryByPath = Dictionary(uniqueKeysWithValues: entries.map { ($0.songPath, $0) })

        switch kind {
        case .recents:
            return library
                .filter { entryByPath[$0.url.path]?.playCount ?? 0 > 0 }
                .sorted {
                    let lhs = entryByPath[$0.url.path]?.lastPlayedAt ?? .distantPast
                    let rhs = entryByPath[$1.url.path]?.lastPlayedAt ?? .distantPast
                    return lhs > rhs
                }
                .prefix(50)
                .map { $0 }

        case .mostlyPlayed:
            return library
                .filter { entryByPath[$0.url.path]?.playCount ?? 0 > 0 }
                .sorted {
                    let lhs = entryByPath[$0.url.path]?.playCount ?? 0
                    let rhs = entryByPath[$1.url.path]?.playCount ?? 0
                    return lhs > rhs
                }
                .prefix(50)
                .map { $0 }

        case .neverPlayed:
            return library
                .filter { (entryByPath[$0.url.path]?.playCount ?? 0) == 0 }
                .sorted {
                    $0.title.localizedStandardCompare($1.title) == .orderedAscending
                }
        }
    }
}
