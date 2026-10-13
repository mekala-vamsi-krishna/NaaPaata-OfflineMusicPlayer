//
//  MusicPlayerView.swift
//  NaaPaataForMac
//

import SwiftUI
import AppKit
import SwiftData

struct MusicPlayerView: View {

    @Environment(\.modelContext) private var modelContext

    @ObservedObject var viewModel: MusicLibraryViewModel
    @Binding var showPlayer: Bool

    @Query private var favourites: [FavouriteSong]

    @State private var isShowingAddToPlaylist = false

    private var song: Song? { viewModel.currentSong }

    private var isCurrentSongFavourite: Bool {
        guard let song = viewModel.currentSong else { return false }
        return favourites.contains { $0.songPath == song.url.path }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = PlayerLayout(size: geo.size)

            ZStack {
                AppColor.surface

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

                playerContent(layout: layout)
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
                    WindowCoordinator.shared.showMiniPlayer(libraryViewModel: viewModel)
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

            Rectangle().fill(.ultraThinMaterial)
        }
        .clipped()
    }

    // MARK: - Player Content

    private func playerContent(layout: PlayerLayout) -> some View {
        let width = layout.contentWidth

        return VStack(spacing: 0) {

            Spacer(minLength: 0)

            artwork(layout: layout)

            Spacer().frame(height: layout.artworkBottomSpacing)

            trackInfo(layout: layout, width: width)

            Spacer().frame(height: layout.trackInfoBottomSpacing)

            progressSection(layout: layout, width: width)

            Spacer().frame(height: layout.progressBottomSpacing)

            transportControls(layout: layout)

            Spacer().frame(height: layout.transportBottomSpacing)

            utilityControls(layout: layout, width: width)

            Spacer(minLength: 0)
        }
        .frame(width: width)
        .padding(.vertical, layout.topPadding)
    }

    // MARK: - Artwork

    private func artwork(layout: PlayerLayout) -> some View {
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
                        .font(.system(size: layout.placeholderIconSize, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .frame(width: layout.artworkSize, height: layout.artworkSize)
        .clipShape(RoundedRectangle(cornerRadius: layout.artworkCornerRadius,
                                    style: .continuous))
        .shadow(
            color: .black.opacity(song == nil ? 0.15 : 0.35),
            radius: layout.artworkShadowRadius,
            y: layout.artworkShadowY
        )
    }

    // MARK: - Track Info

    private func trackInfo(layout: PlayerLayout, width: CGFloat) -> some View {
        VStack(spacing: layout.titleArtistSpacing) {
            if let song {
                MarqueeText(
                    text: song.title,
                    font: .system(size: layout.titleFontSize, weight: .semibold),
                    color: .white
                )
                .frame(width: width)
                .frame(height: layout.titleFrameHeight)

                MarqueeText(
                    text: song.artist,
                    font: .system(size: layout.artistFontSize),
                    color: .white.opacity(0.75)
                )
                .frame(width: width)
                .frame(height: layout.artistFrameHeight)
            } else {
                Text("Not Playing")
                    .font(.system(size: layout.titleFontSize, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: width)
                    .frame(height: layout.titleFrameHeight)

                Text("Select a song to begin")
                    .font(.system(size: layout.artistFontSize))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(width: width)
                    .frame(height: layout.artistFrameHeight)
            }
        }
        .frame(width: width)
    }

    // MARK: - Progress

    private func progressSection(layout: PlayerLayout, width: CGFloat) -> some View {
        VStack(spacing: layout.sliderTimeSpacing) {
            ThickSlider(
                value: song != nil ? viewModel.progress : 0,
                trackHeight: layout.sliderTrackHeight,
                thumbSize: layout.sliderThumbSize,
                onSeek: { progress in
                    guard song != nil else { return }
                    viewModel.seek(toProgress: progress)
                }
            )
            .frame(width: width)
            .frame(height: layout.sliderContainerHeight)

            HStack {
                Text(song != nil ? elapsedString : "0:00")
                    .font(.system(size: layout.timeFontSize, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.78))

                Spacer()

                Text(song?.formattedDuration ?? "0:00")
                    .font(.system(size: layout.timeFontSize, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(width: width)
        }
        .frame(width: width)
    }

    // MARK: - Transport

    private func transportControls(layout: PlayerLayout) -> some View {
        HStack(spacing: layout.transportButtonSpacing) {
            NudgeButton(
                systemName: "backward.fill",
                direction: -1,
                size: layout.controlButtonSize,
                iconSize: layout.transportIconSize,
                action: viewModel.playPrevious
            )

            playPauseButton(layout: layout)

            NudgeButton(
                systemName: "forward.fill",
                direction: 1,
                size: layout.controlButtonSize,
                iconSize: layout.transportIconSize,
                action: viewModel.playNext
            )
        }
    }

    private func playPauseButton(layout: PlayerLayout) -> some View {
        Button {
            viewModel.togglePlayPause()
        } label: {
            Image(systemName: viewModel.isPlaying && song != nil ? "pause.fill" : "play.fill")
                .font(.system(size: layout.playIconSize, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: layout.playButtonSize, height: layout.playButtonSize)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.6),
                   value: viewModel.isPlaying)
    }

    // MARK: - Utility

    private func utilityControls(layout: PlayerLayout, width: CGFloat) -> some View {
        // Each button gets exactly `width / 4`. The HStack has a fixed
        // total width, so the four buttons always fit inside it.
        HStack(spacing: 0) {
            utilityButton(
                systemName: "shuffle",
                isActive: viewModel.isShuffled,
                showsActiveBackground: true,
                layout: layout
            ) {
                viewModel.toggleShuffle()
            }
            .frame(maxWidth: .infinity)

            utilityButton(
                systemName: viewModel.repeatMode.systemImage,
                isActive: viewModel.repeatMode != .off,
                showsActiveBackground: true,
                layout: layout
            ) {
                viewModel.cycleRepeatMode()
            }
            .frame(maxWidth: .infinity)

            utilityButton(
                systemName: "text.badge.plus",
                isActive: false,
                layout: layout
            ) {
                guard song != nil else { return }
                isShowingAddToPlaylist = true
            }
            .frame(maxWidth: .infinity)

            utilityButton(
                systemName: isCurrentSongFavourite ? "heart.fill" : "heart",
                isActive: isCurrentSongFavourite,
                layout: layout
            ) {
                toggleFavourite()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: width)
        .frame(height: layout.utilityButtonSize)
    }

    private func utilityButton(
        systemName: String,
        isActive: Bool,
        showsActiveBackground: Bool = false,
        layout: PlayerLayout,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                if isActive && showsActiveBackground {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: layout.utilityActiveCircleSize,
                               height: layout.utilityActiveCircleSize)
                }

                Image(systemName: systemName)
                    .font(.system(size: layout.utilityIconSize, weight: .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .contentTransition(.symbolEffect(.replace))
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
    }

    private func toggleFavourite() {
        guard let song = viewModel.currentSong else { return }
        try? FavouritesService(context: modelContext).toggleFavourite(song.url)
    }

    private var elapsedString: String {
        let total = Int(viewModel.elapsed.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
