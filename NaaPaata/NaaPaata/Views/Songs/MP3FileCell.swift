//
//  MP3FileCell.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import AVFoundation

struct MP3FileCell: View {
    let song: Song
    @EnvironmentObject var musicManager: MusicPlayerManager
    @EnvironmentObject var albumsViewModel: AlbumsViewModel

    // Callback for navigation to album detail
    var onGoToAlbum: ((_ albumTitle: String, _ artwork: UIImage?, _ songs: [Song]) -> Void)?

    @State private var showSongInfoSheet = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showDeleteAlert = false
    @State private var showAddToPlaylist = false
    @State private var artwork: UIImage?

    var body: some View {
        HStack(spacing: 15) {
            // Artwork
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .foregroundColor(AppColors.primary)
                    )
                    .task {
                        self.artwork = await musicManager.loadArtworkAsync(for: song)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if musicManager.currentSong?.urlString == song.urlString {
                EqualizerBars(isPlaying: musicManager.isPlaying)
                    .frame(width: 20, height: 20)
            }

            Menu {
                Button {
                    musicManager.addToQueueNext(song)
                } label: {
                    Label("Play Next", systemImage: "text.insert")
                }

                Button {
                    showSongInfoSheet = true
                } label: {
                    Label("Info", systemImage: "info.circle")
                }

                Button {
                    let matched = albumsViewModel.albums.first(where: { $0.name == song.album })
                    let albumTitle = matched?.name ?? song.album
                    let artwork = matched?.artworkImage ?? song.artworkImage
                    let songs = matched?.songs ?? [song]
                    onGoToAlbum?(albumTitle, artwork, songs)
                } label: {
                    Label("Go to Album", systemImage: "square.stack")
                }

                Button {
                    if let shareURL = song.resolvedURL ?? song.url {
                        shareItems = [shareURL]
                        showShareSheet = true
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button {
                    showAddToPlaylist = true
                } label: {
                    Label("Add to Playlist", systemImage: "music.note.list")
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }

            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .padding(10)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showAddToPlaylist) {
            AddToPlaylistView(song: song)
                .environmentObject(musicManager)
        }
        .sheet(isPresented: $showSongInfoSheet) {
            NavigationStack {
                SongInfoView(song: song)
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
                .presentationDetents([.fraction(0.4)])
        }
        .alert("Delete Song?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                musicManager.delete(song: song)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(song.title)\" from your device?")
        }
    }
}
