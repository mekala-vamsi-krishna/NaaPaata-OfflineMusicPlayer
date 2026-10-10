//
//  PlaylistSongRowView.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct PlaylistSongRowView: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var router: AppRouter

    let song: Song
    let onPlay: () -> Void
    let onDelete: () -> Void

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var isCurrentSong: Bool {
        libraryViewModel.currentSong?.id == song.id
    }

    private var artworkImage: UIImage? {
        guard let data = song.artworkData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        HStack(spacing: 15) {

            artwork

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(isCurrentSong ? Color.accentColor : .primary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isCurrentSong {
                EqualizerBars(
                    isPlaying: libraryViewModel.isPlaying,
                    size: 18,
                    barCount: 3,
                    color: .accentColor
                )
            }

            menu
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onPlay() }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
                .presentationDetents([.fraction(0.4)])
        }
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artwork: some View {
        if let artworkImage {
            Image(uiImage: artworkImage)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.15))

                Image(systemName: "music.note")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 50, height: 50)
        }
    }

    // MARK: - Menu

    private var menu: some View {
        Menu {
            Button(action: onPlay) {
                Label("Play Now", systemImage: "play.fill")
            }

            Button {
                libraryViewModel.enqueueNext(song)
            } label: {
                Label("Play Next", systemImage: "text.insert")
            }

            Button {
                goToAlbum()
            } label: {
                Label("Go to Album", systemImage: "square.stack")
            }

            Button {
                shareItems = [song.url]
                showShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Remove", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .padding(10)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Actions

    private func goToAlbum() {
        guard let album = libraryViewModel.albums.first(where: {
            $0.title == song.album
        }) else {
            print("⚠️ No album found for: \(song.album)")
            return
        }

        print("→ Pushing album: \(album.title)")
        router.push(album)
    }
}
