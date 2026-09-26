//
//  MiniPlayerView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI
import AppKit
import SwiftData

struct MiniPlayerView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    @Environment(\.modelContext) private var modelContext

    @Query private var favourites: [FavouriteSong]

    @State private var isHovering = false
    @State private var isShowingInfo = false
    @State private var addToPlaylistMode: AddToPlaylistMode?

    private var song: Song? { viewModel.currentSong }
    private var hasSong: Bool { song != nil }

    private var isCurrentSongFavourite: Bool {
        guard let song = viewModel.currentSong else { return false }
        return favourites.contains { $0.songPath == song.url.path }
    }

    var body: some View {
        ZStack {
            artworkBackground
            controlsOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.06))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .background(
            MiniPlayerWindowConfigurator(isHovering: $isHovering)
                .frame(width: 0, height: 0)
        )
        .ignoresSafeArea(.all, edges: .all)
        .onDisappear {
            WindowCoordinator.shared.showMainWindow()
        }
        .sheet(isPresented: $isShowingInfo) {
            if let song { SongInfoView(song: song) }
        }
        .sheet(item: $addToPlaylistMode) { mode in
            switch mode {
            case .new:
                if let song {
                    CreatePlaylistSheet(initialSongURLs: [song.url]) { name, description, artworkData, songURLs in
                        _ = try? PlaylistService(context: modelContext).createPlaylist(
                            name: name,
                            description: description,
                            artworkData: artworkData,
                            songURLs: songURLs
                        )
                    }
                }
            case .existing:
                if let song { AddToPlaylistSheet(song: song) }
            }
        }
        .task {
            await viewModel.restoreLastSession()
        }
    }

    // MARK: - Artwork

    private var artworkBackground: some View {
        GeometryReader { geo in
            ZStack {
                if let data = song?.artworkData,
                   let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Solid gray, not transparent.
                    ZStack {
                        Color(white: 0.18)

                        LinearGradient(
                            colors: [
                                Color(white: 0.22),
                                Color(white: 0.14)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Image(systemName: "music.note")
                            .font(.system(size: 100, weight: .light))
                            .foregroundStyle(.white.opacity(0.18))
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        ZStack(alignment: .bottom) {
            bottomScrim
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if isHovering {
                    bottomControls
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(16)
        }
        .animation(.easeInOut(duration: 0.25), value: isHovering)
    }
    
    // MARK: - Bottom Scrim

    private var bottomScrim: some View {
        ZStack {
            // Blur layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,  location: 0.35),
                            .init(color: .black,  location: 0.75),
                            .init(color: .black,  location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Darkening gradient
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.0),  location: 0.35),
                    .init(color: .black.opacity(0.55), location: 0.7),
                    .init(color: .black.opacity(0.85), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(alignment: .leading, spacing: 10) {

            // title/artist + heart + menu
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    if let song {
                        EdgeFadeMarquee(
                            text: song.title,
                            font: .system(size: 15, weight: .semibold),
                            color: .white
                        )
                        .frame(height: 20)

                        EdgeFadeMarquee(
                            text: song.artist,
                            font: .system(size: 12),
                            color: .white.opacity(0.78)
                        )
                        .frame(height: 16)
                    } else {
                        // Reserve the same space — no text rendered.
                        Color.clear.frame(height: 20)
                        Color.clear.frame(height: 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    toggleFavourite()
                } label: {
                    Image(systemName: isCurrentSongFavourite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(hasSong ? .white : .white.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: isCurrentSongFavourite)
                }
                .buttonStyle(.plain)
                .disabled(!hasSong)
                .focusable(false)

                menuButton
                    .opacity(hasSong ? 1 : 0.3)
                    .disabled(!hasSong)
            }

            // Progress bar
            ThickSlider(
                value: hasSong ? viewModel.progress : 0,
                trackHeight: 3,
                thumbSize: 9,
                onSeek: { progress in
                    guard hasSong else { return }
                    viewModel.seek(toProgress: progress)
                }
            )
            .frame(height: 12)
            .opacity(hasSong ? 1 : 0.3)

            // ─── Transport + shuffle/repeat ───
            HStack(spacing: 18) {
                Spacer(minLength: 0)

                utilityButton(
                    systemName: "shuffle",
                    isActive: viewModel.isShuffled,
                    showsActiveBackground: true
                ) {
                    viewModel.toggleShuffle()
                }

                Spacer(minLength: 12)

                transportButton(systemName: "backward.fill", size: 16) {
                    viewModel.playPrevious()
                }
                .opacity(hasSong ? 1 : 0.3)
                .disabled(!hasSong)
                .focusable(false)

                playPauseButton

                transportButton(systemName: "forward.fill", size: 16) {
                    viewModel.playNext()
                }
                .opacity(hasSong ? 1 : 0.3)
                .disabled(!hasSong)
                .focusable(false)

                Spacer(minLength: 12)

                utilityButton(
                    systemName: viewModel.repeatMode.systemImage,
                    isActive: viewModel.repeatMode != .off,
                    showsActiveBackground: true
                ) {
                    viewModel.cycleRepeatMode()
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Play / Pause (dual behaviour)

    private var playPauseButton: some View {
        Button {
            if hasSong {
                viewModel.togglePlayPause()
            } else {
                startLibraryPlayback()
            }
        } label: {
            Image(systemName: playPauseSymbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.isPlaying)
    }

    private var playPauseSymbol: String {
        if hasSong && viewModel.isPlaying {
            return "pause.fill"
        }
        return "play.fill"
    }

    // MARK: - Button Builders

    private func transportButton(
        systemName: String,
        size: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                        .fill(.white.opacity(0.18))
                        .frame(width: 26, height: 26)
                        .transition(.scale.combined(with: .opacity))
                }

                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.85))
            }
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    private var menuButton: some View {
        Menu {
            Menu {
                Button("New Playlist") { addToPlaylistMode = .new }
                Button("Existing Playlist") { addToPlaylistMode = .existing }
            } label: {
                Label("Add to Playlist", systemImage: "text.badge.plus")
            }

            Divider()

            Button {
                if let song { viewModel.enqueueNext(song) }
            } label: {
                Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }

            Divider()

            Button {
                if let song {
                    NSWorkspace.shared.activateFileViewerSelecting([song.url])
                }
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }

            Button {
                isShowingInfo = true
            } label: {
                Label("Song Info", systemImage: "info.circle")
            }
        } label: {
            ZStack {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .focusable(false)
    }

    // MARK: - Playback starter

    private func startLibraryPlayback() {
        if viewModel.songs.isEmpty {
            Task { @MainActor in
                await viewModel.loadLibrary()
                guard !viewModel.songs.isEmpty else { return }
                viewModel.playAll(viewModel.songs)
            }
        } else {
            viewModel.playAll(viewModel.songs)
        }
    }

    // MARK: - Favourite

    private func toggleFavourite() {
        guard let song else { return }
        try? FavouritesService(context: modelContext).toggleFavourite(song.url)
    }
}

// MARK: - EdgeFadeMarquee

private struct EdgeFadeMarquee: View {

    let text: String
    let font: Font
    let color: Color

    private let gap: CGFloat = 40
    private let pointsPerSecond: CGFloat = 30
    private let pauseDuration: Double = 1.5

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let needsScroll = textWidth > containerWidth

            HStack(spacing: gap) {
                Text(text)
                    .font(font)
                    .foregroundStyle(color)
                    .fixedSize()

                if needsScroll {
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .fixedSize()
                }
            }
            .offset(x: offset)
            .frame(width: containerWidth, alignment: .leading)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.02),
                        .init(color: .black, location: 0.98),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .background(
                Text(text)
                    .font(font)
                    .fixedSize()
                    .hidden()
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.preference(
                                key: MarqueeWidthKey.self,
                                value: textGeo.size.width
                            )
                        }
                    )
            )
            .onPreferenceChange(MarqueeWidthKey.self) { newWidth in
                textWidth = newWidth
                startAnimationIfNeeded(containerWidth: containerWidth)
            }
            .onChange(of: text) { _, _ in
                offset = 0
                startAnimationIfNeeded(containerWidth: containerWidth)
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
        }
    }

    private func startAnimationIfNeeded(containerWidth: CGFloat) {
        animationTask?.cancel()
        offset = 0

        guard textWidth > containerWidth, textWidth > 0 else { return }

        let totalDistance = textWidth + gap
        let scrollDuration = Double(totalDistance / pointsPerSecond)

        animationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))

            while !Task.isCancelled {
                withAnimation(.linear(duration: scrollDuration)) {
                    offset = -totalDistance
                }

                try? await Task.sleep(nanoseconds: UInt64(scrollDuration * 1_000_000_000))
                if Task.isCancelled { break }

                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    offset = 0
                }

                try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
            }
        }
    }
}

private struct MarqueeWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
