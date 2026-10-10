//
//  SmartPlaylistDetailView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/9/26.
//

import SwiftUI
import SwiftData

struct SmartPlaylistDetailView: View {

    let kind: SmartPlaylistKind
    @ObservedObject var viewModel: MusicLibraryViewModel
    @EnvironmentObject private var folderService: DocumentFolderService
    @Environment(\.modelContext) private var modelContext

    @State private var songToAddToPlaylist: Song?
    @State private var infoSong: Song?

    private var service: SmartPlaylistService {
        SmartPlaylistService(context: modelContext, folderService: folderService)
    }

    private var songs: [Song] {
        service.compute(kind: kind, from: viewModel.songs)
    }

    private var playlist: SmartPlaylist {
        SmartPlaylist(kind: kind, songs: songs)
    }

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
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $infoSong) { song in
            NavigationStack {
                SongInfoView(song: song)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { infoSong = nil }
                        }
                    }
            }
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
                Text(kind.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)

                Text(playlist.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 16)
    }

    private var artworkHero: some View {
        ZStack {
            kind.gradient

            Image(systemName: kind.systemImage)
                .font(.system(size: 58, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))

            if let data = playlist.artworkData,
               let image = UIImage(data: data) {
                GeometryReader { geo in
                    let corner = geo.size.width * 0.40

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: corner, height: corner)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .rotationEffect(.degrees(-6))
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomTrailing
                        )
                        .padding(14)
                }
            }
        }
        .frame(width: 180, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.20), radius: 16, y: 8)
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
                smartSongRow(song: song)
                    .padding(.horizontal, 20)

                if index < songs.count - 1 {
                    Divider()
                        .padding(.leading, 20 + 52 + 14)
                }
            }
        }
    }

    private func smartSongRow(song: Song) -> some View {
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

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
