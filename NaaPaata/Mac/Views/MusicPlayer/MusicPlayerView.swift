//
//  MusicPlayerView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/14/26.
//

import SwiftUI
import AppKit
import SwiftData

struct MusicPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @ObservedObject var viewModel: MusicLibraryViewModel
    @Binding var showPlayer: Bool
    
    @Query private var favourites: [FavouriteSong]

    @State private var isShowingAddToPlaylist = false

    var onClose: () -> Void = {}
    
    private var song: Song? {
        viewModel.currentSong
    }

    private var isCurrentSongFavourite: Bool {
        guard let song = viewModel.currentSong else { return false }
        return favourites.contains { $0.songPath == song.url.path }
    }

    // MARK: - Constants

    private let playerWidth: CGFloat = 320
    private let horizontalPadding: CGFloat = 24
    private let artworkSize: CGFloat = 260
    private let artworkCornerRadius: CGFloat = 16
    private let controlButtonSize: CGFloat = 42
    private let playButtonSize: CGFloat = 54
    private let utilityButtonSize: CGFloat = 42

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.surface
                .ignoresSafeArea()

            artworkBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.00),
                    .black.opacity(0.12),
                    .black.opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()

            playerContent
                .frame(width: playerWidth)
                .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $isShowingAddToPlaylist) {
            if let song = viewModel.currentSong {
                AddToPlaylistSheet(song: song)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    WindowCoordinator.shared.hideMainWindow()
                    openWindow(id: WindowID.miniPlayer)
                } label: {
                    Label("Mini Player", systemImage: "pip.enter")
                }
                .help("Open Mini Player")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPlayer.toggle()
                    }
                } label: {
                    Label(
                        showPlayer ? "Hide Player" : "Show Player",
                        systemImage: "sidebar.right"
                    )
                }
                .help(showPlayer ? "Hide Player" : "Show Player")
            }
        }
    }

    // MARK: - Artwork Background

    private var artworkBackground: some View {
        ZStack {
            if let data = song?.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 55)
                    .opacity(0.55)
            } else {
                Color.clear
            }

            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .clipped()
    }

    private func toggleFavourite() {
        guard let song = viewModel.currentSong else { return }
        try? FavouritesService(context: modelContext).toggleFavourite(song.url)
    }

    // MARK: - Player Content

    private var playerContent: some View {
        VStack(spacing: 0) {
            artwork
                .padding(.bottom, 22)

            trackInfo
                .padding(.bottom, 20)

            progressSection
                .padding(.bottom, 20)

            backwardForwardPlayControls
                .padding(.bottom, 12)

            utilityControls
        }
        .frame(width: playerWidth)
        .padding(.top, 28)
        .padding(.bottom, 24)
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            if let data = song?.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                        .grayscale(1)
                        .opacity(0.35)

                    Image(systemName: "music.note")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .frame(width: artworkSize, height: artworkSize)
        .clipShape(
            RoundedRectangle(
                cornerRadius: artworkCornerRadius,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(song == nil ? 0.15 : 0.35),
            radius: 18,
            y: 10
        )
    }

    // MARK: - Track Information

    private var trackInfo: some View {
        VStack(spacing: 5) {
            if let song {
                MarqueeText(
                    text: song.title,
                    font: .system(size: 16, weight: .semibold),
                    color: .white
                )
                .frame(width: playerWidth - horizontalPadding * 2, height: 22)

                MarqueeText(
                    text: song.artist,
                    font: .system(size: 13),
                    color: .white.opacity(0.75)
                )
                .frame(width: playerWidth - horizontalPadding * 2, height: 18)
            } else {
                Text("Not Playing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: playerWidth - horizontalPadding * 2, height: 22)

                Text("Select a song to begin")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(width: playerWidth - horizontalPadding * 2, height: 18)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 6) {
            ThickSlider(
                value: song != nil ? viewModel.progress : 0,
                trackHeight: 4,
                thumbSize: 12,
                onSeek: { progress in
                    guard song != nil else { return }
                    viewModel.seek(toProgress: progress)
                }
            )
            .frame(
                width: playerWidth - horizontalPadding * 2,
                height: 20
            )

            HStack {
                Text(song != nil ? elapsedString : "0:00")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))

                Spacer()

                Text(song?.formattedDuration ?? "0:00")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(width: playerWidth - horizontalPadding * 2)
        }
    }

    // MARK: - Transport Controls

    private var backwardForwardPlayControls: some View {
        HStack(spacing: 22) {
            NudgeButton(
                systemName: "backward.fill",
                direction: -1,
                size: controlButtonSize,
                action: viewModel.playPrevious
            )

            playPauseButton

            NudgeButton(
                systemName: "forward.fill",
                direction: 1,
                size: controlButtonSize,
                action: viewModel.playNext
            )
        }
        .frame(width: playerWidth)
    }

    // MARK: - Play / Pause

    private var playPauseButton: some View {
        Button {
            viewModel.togglePlayPause()
        } label: {
            Image(systemName: viewModel.isPlaying && song != nil ? "pause.fill" : "play.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: playButtonSize, height: playButtonSize)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.6),
            value: viewModel.isPlaying
        )
    }

    // MARK: - Utility Controls

    private var utilityControls: some View {
        HStack(spacing: 0) {
            utilityButton(
                systemName: "shuffle",
                isActive: viewModel.isShuffled,
                showsActiveBackground: true
            ) {
                viewModel.toggleShuffle()
            }

            utilityButton(
                systemName: viewModel.repeatMode.systemImage,
                isActive: viewModel.repeatMode != .off,
                showsActiveBackground: true
            ) {
                viewModel.cycleRepeatMode()
            }

            utilityButton(
                systemName: "text.badge.plus",
                isActive: false
            ) {
                guard song != nil else { return }
                isShowingAddToPlaylist = true
            }

            utilityButton(
                systemName: isCurrentSongFavourite ? "heart.fill" : "heart",
                isActive: isCurrentSongFavourite
            ) {
                toggleFavourite()
            }
        }
        .frame(
            width: playerWidth - horizontalPadding * 2,
            height: utilityButtonSize
        )
    }

    private func utilityButton(
        systemName: String,
        isActive: Bool,
        showsActiveBackground: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                if isActive && showsActiveBackground {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 32, height: 32)
                        .transition(.scale.combined(with: .opacity))
                }

                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.72))
            }
            .frame(width: utilityButtonSize, height: utilityButtonSize)
            .contentShape(Rectangle())
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var elapsedString: String {
        let total = Int(viewModel.elapsed.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Nudge Button

private struct NudgeButton: View {
    @State private var isAnimating = false
    
    let systemName: String
    let direction: CGFloat
    let size: CGFloat
    let action: () -> Void

    // Slide distance and timing
    private let slideDistance: CGFloat = 16
    private let exitDuration: Double = 0.16
    private let entryDuration: Double = 0.32

    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Button {
            action()
            nudge()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .offset(x: offsetX)
                .opacity(opacity)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    private func nudge() {
        guard !isAnimating else { return }
        isAnimating = true

        withAnimation(.easeIn(duration: exitDuration)) {
            offsetX = direction * slideDistance
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                offsetX = -direction * slideDistance
            }

            withAnimation(.easeOut(duration: entryDuration)) {
                offsetX = 0
                opacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + entryDuration) {
                isAnimating = false
            }
        }
    }
}
