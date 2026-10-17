//
//  Artwork.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/15/26.
//

import SwiftUI

struct Artwork: View {

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

    var namespace: Namespace.ID
    var artworkSize: CGFloat
    var dragOffset: CGFloat

    /// Visual gap between neighbouring artworks while swiping.
    private let gap: CGFloat = 24

    var body: some View {
        let queue = libraryViewModel.queueSnapshot
        let currentIndex = libraryViewModel.currentQueueIndex ?? 0

        ZStack {
            if !queue.isEmpty {
                let windowStart = max(0, currentIndex - 1)
                let windowEnd = min(queue.count - 1, currentIndex + 1)

                ForEach(windowStart...windowEnd, id: \.self) { idx in
                    let song = queue[idx]
                    let isCurrent = idx == currentIndex
                    let step = artworkSize + gap
                    let offsetX =
                        CGFloat(idx - currentIndex) * step + dragOffset

                    artworkSlot(song: song, isCurrent: isCurrent)
                        .offset(x: offsetX)
                        .clipShape(.rect(cornerRadius: 10))
                        .transition(.identity)
                }
            } else if let song = libraryViewModel.currentSong {
                artworkSlot(song: song, isCurrent: true)
            }
        }
        .frame(width: artworkSize, height: artworkSize)
        .clipped()
    }

    @ViewBuilder
    private func artworkSlot(song: Song, isCurrent: Bool) -> some View {
        if isCurrent {
            artworkContent(for: song)
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(.rect(cornerRadius: 10))
                .matchedGeometryEffect(id: "artwork", in: namespace)
        } else {
            artworkContent(for: song)
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(.rect(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func artworkContent(for song: Song) -> some View {
        if let data = song.artworkData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x4B0B7E),
                            Color(hex: 0x9C1BA8),
                            Color(hex: 0xC21AA9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                }
        }
    }
}
