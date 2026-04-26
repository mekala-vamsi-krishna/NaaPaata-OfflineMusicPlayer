//
//  PlaylistSongRowView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import SwiftUI
import AVFoundation

struct PlaylistSongRowView: View {
    @EnvironmentObject var musicManager: MusicPlayerManager
    
    let song: Song
    let editMode: EditMode  // Keep for compatibility but not used
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    // Async Artwork
    @State private var artwork: UIImage?
    
    // Share Properties
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        HStack(spacing: 15) {
            // Artwork
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .background(AppColors.background.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .frame(width: 50, height: 50)
                    .background(AppColors.background.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(AppColors.primary)
                    .task {
                        self.artwork = await musicManager.loadArtworkAsync(for: song)
                    }
            }

            // Song details
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

            // Now Playing Indicator
            if musicManager.currentSong == song {
                EqualizerBars(isPlaying: musicManager.isPlaying)
                    .frame(width: 20, height: 20)
            }

            // Ellipsis menu
            Menu {
                Button(action: onPlay) {
                    Label("Play Now", systemImage: "play.fill")
                }
                
                Button {
                    musicManager.addToQueueNext(song)
                } label: {
                    Label("Play Next", systemImage: "text.insert")
                }

                Button {
                    shareItems = [song.url ?? URL(fileURLWithPath: "")]
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
                    .foregroundColor(.gray)
                    .padding(10)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        // Share Sheet
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
                .presentationDetents([.fraction(0.4)])
        }
    }
}

