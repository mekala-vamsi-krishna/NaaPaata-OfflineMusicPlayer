//
//  MusicPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import UIKit
import SwiftData

struct MusicPlayerView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var folderService: DocumentFolderService
    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var sleepTimerManager: SleepTimerManager
    @EnvironmentObject private var progressStore: PlaybackProgressStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Query private var favourites: [FavouriteSong]

    // MARK: - Dependencies

    let dismissAction: () -> Void
    let onDismissalProgressChanged: (CGFloat) -> Void
    let onGoToAlbum: (Album) -> Void

    // MARK: - State

    @State private var showSleepTimerSheet = false
    @State private var showAddToPlaylist = false
    @State private var infoSong: Song?
    @State private var showDeleteAlert = false
    @State private var dragOffset: CGFloat = 0

    private var dismissThreshold: CGFloat { 120 }

    // MARK: - Derived

    private var song: Song? { libraryViewModel.currentSong }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var repeatIconName: String {
        libraryViewModel.repeatMode == .one ? "repeat.1" : "repeat"
    }

    private var isCurrentSongFavourite: Bool {
        guard let song,
              let relativePath = folderService.relativePath(for: song.url)
        else { return false }
        return favourites.contains { $0.songRelativePath == relativePath }
    }

    private var duration: TimeInterval { song?.duration ?? 0 }
    private var currentTime: TimeInterval { progressStore.elapsed }
    private var progress: Double { progressStore.progress }

    private var artworkImage: UIImage? {
        guard let data = song?.artworkData else { return nil }
        return UIImage(data: data)
    }

    private var dismissalProgress: CGFloat {
        min(max(dragOffset / 520, 0), 1)
    }

    private var playerTopCornerRadius: CGFloat {
        let ramp = min(dismissalProgress / 0.05, 1)
        return 44 * ramp
    }

    private var backdropOpacity: CGFloat { 0 }

    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 59
    }

    private var bottomSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 34
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                playerBackground

                VStack(spacing: 0) {
                    grabberBar
                        .padding(.top, topSafeAreaInset + 14)
                        .padding(.bottom, 12)

                    if isLandscape {
                        landscapeLayout(in: geometry)
                    } else {
                        portraitLayout(in: geometry)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .offset(y: dragOffset)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: playerTopCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: playerTopCornerRadius,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
            .gesture(dismissGesture(screenHeight: geometry.size.height))
        }
        .ignoresSafeArea()
        .background(
            Color.black
                .opacity(backdropOpacity)
                .ignoresSafeArea()
        )
        .onAppear { dragOffset = 0 }
        .preferredColorScheme(.dark)

        // MARK: Sheets

        .sheet(isPresented: $showSleepTimerSheet) {
            SleepTimerPickerView()
                .environmentObject(sleepTimerManager)
        }

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

        .sheet(isPresented: $showAddToPlaylist) {
            if let song {
                AddToPlaylistView(song: song)
            }
        }

        .alert("Delete Song?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let song {
                    libraryViewModel.deleteSong(song)
                    dismissAction()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(song?.title ?? "")\" from your device?")
        }
    }

    // MARK: - Grabber

    private var grabberBar: some View {
        Capsule()
            .fill(.white.opacity(0.35))
            .frame(width: 36, height: 5)
    }

    // MARK: - Portrait layout

    private func portraitLayout(in geometry: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 32

        // Height reserved for everything below the artwork.
        let reservedBelowArtwork: CGFloat = 240 + bottomSafeAreaInset

        // Space left over for artwork after the grabber.
        let availableForArtwork = geometry.size.height
            - topSafeAreaInset
            - 14 - 5 - 12                 // grabber block
            - reservedBelowArtwork

        let maxByWidth = geometry.size.width - (horizontalPadding * 2)
        let artworkSize = max(min(maxByWidth, availableForArtwork, 420), 160)

        return VStack(spacing: 0) {
            artworkView(size: artworkSize)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 24)

            headerRow
                .padding(.horizontal, horizontalPadding)

            Spacer(minLength: 20)

            progressSection
                .padding(.horizontal, horizontalPadding)

            Spacer(minLength: 20)

            playbackControlsRow
                .padding(.horizontal, horizontalPadding)

            Spacer(minLength: 0)
        }
        .padding(.bottom, bottomSafeAreaInset + 12)
    }

    // MARK: - Landscape layout

    private func landscapeLayout(in geometry: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 32
        let hStackSpacing: CGFloat = 24

        let availableWidth = geometry.size.width
            - (horizontalPadding * 2)
            - hStackSpacing

        let reservedVertical = topSafeAreaInset
            + 14 + 5 + 12               // grabber block
            + bottomSafeAreaInset
            + 16                        // bottom padding
            + 24                        // breathing room

        let availableHeight = geometry.size.height - reservedVertical

        let artworkFromWidth = availableWidth * 0.44
        let artworkSize = max(min(artworkFromWidth, availableHeight, 420), 160)

        return HStack(alignment: .center, spacing: hStackSpacing) {
            artworkView(size: artworkSize)

            VStack(alignment: .leading, spacing: 20) {
                headerRow
                progressSection
                playbackControlsRow

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, bottomSafeAreaInset + 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Header row

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 8) {

            VStack(alignment: .leading, spacing: 4) {
                MarqueeText(
                    text: song?.title ?? "Not Playing",
                    font: .system(size: 20, weight: .semibold, design: .rounded),
                    color: .white
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 26)

                MarqueeText(
                    text: song?.artist ?? "Unknown Artist",
                    font: .system(size: 14),
                    color: .white.opacity(0.65)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Favourite
            Button {
                toggleFavourite()
            } label: {
                Image(systemName: isCurrentSongFavourite ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isCurrentSongFavourite ? .pink : .white)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isCurrentSongFavourite)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isCurrentSongFavourite
                ? "Remove from Favourites"
                : "Add to Favourites"
            )

            // Menu
            Menu {
                Button {
                    infoSong = song
                } label: {
                    Label("Info", systemImage: "info.circle")
                }

                Button {
                    showAddToPlaylist = true
                } label: {
                    Label("Add to Playlist", systemImage: "music.note.list")
                }

                Button {
                    goToAlbum()
                } label: {
                    Label("Go to Album", systemImage: "square.stack")
                }

                Button {
                    showSleepTimerSheet = true
                } label: {
                    if sleepTimerManager.isTimerActive {
                        Label(
                            "Timer · \(sleepTimerManager.formattedTimeRemaining)",
                            systemImage: "moon.fill"
                        )
                    } else {
                        Label("Set Timer", systemImage: "moon.stars")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .tint(.red)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .tint(.primary)

        }
    }

    // MARK: - Progress section

    private var progressSection: some View {
        PlayerProgressSection(
            currentTime: currentTime,
            duration: duration,
            onSeek: { seek(to: $0) }
        )
    }

    // MARK: - Playback controls

    private var playbackControlsRow: some View {
        HStack(spacing: 0) {
            ControlButton(
                icon: "shuffle",
                isActive: libraryViewModel.isShuffled,
                action: {
                    HapticManager.shared.medium()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        libraryViewModel.toggleShuffle()
                    }
                }
            )
            .frame(width: 44)

            Spacer(minLength: 8)

            HStack(spacing: 26) {
                PlaybackButton(
                    icon: "backward.fill",
                    size: 26,
                    action: {
                        HapticManager.shared.light()
                        libraryViewModel.playPrevious()
                    }
                )

                PlaybackButton(
                    icon: libraryViewModel.isPlaying ? "pause.fill" : "play.fill",
                    size: 40,
                    action: {
                        HapticManager.shared.medium()
                        libraryViewModel.togglePlayPause()
                    }
                )

                PlaybackButton(
                    icon: "forward.fill",
                    size: 26,
                    action: {
                        HapticManager.shared.light()
                        libraryViewModel.playNext()
                    }
                )
            }

            Spacer(minLength: 8)

            ControlButton(
                icon: repeatIconName,
                isActive: libraryViewModel.repeatMode != .off,
                action: {
                    HapticManager.shared.medium()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        libraryViewModel.cycleRepeatMode()
                    }
                }
            )
            .frame(width: 44)
        }
    }

    // MARK: - Artwork

    @ViewBuilder
    private func artworkView(size: CGFloat) -> some View {
        Group {
            if let artworkImage {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    brandGradient.grayscale(1).opacity(0.35)

                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.28, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
    }

    // MARK: - Background

    @ViewBuilder
    private var playerBackground: some View {
        ZStack {
            Color.black

            if let artworkImage {
                GeometryReader { geo in
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(1.2)
                        .blur(radius: 80)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.55),
                                    Color.black.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(1 - min(dismissalProgress / 0.30, 1))
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Brand gradient

    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0x4B0B7E),
                Color(hex: 0x9C1BA8),
                Color(hex: 0xC21AA9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Drag gesture

    private func dismissGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let translation = value.translation.height
                dragOffset = translation > 0 ? translation : 0

                let progress = min(max(dragOffset / 520, 0), 1)
                onDismissalProgressChanged(progress)
            }
            .onEnded { value in
                let projected = max(
                    value.translation.height,
                    value.predictedEndTranslation.height
                )

                if projected > dismissThreshold {
                    onDismissalProgressChanged(1)

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        dragOffset = screenHeight
                    } completion: {
                        dismissAction()
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        dragOffset = 0
                        onDismissalProgressChanged(0)
                    }
                }
            }
    }

    // MARK: - Actions

    private func toggleFavourite() {
        guard let song,
              let relativePath = folderService.relativePath(for: song.url)
        else { return }

        HapticManager.shared.light()
        let service = FavouritesService(context: modelContext)
        try? service.toggleFavourite(relativePath)
    }

    private func goToAlbum() {
        guard let song,
              let album = libraryViewModel.albums.first(where: {
                  $0.title == song.album
              })
        else { return }

        HapticManager.shared.light()
        onGoToAlbum(album)
    }

    private func seek(to time: TimeInterval) {
        guard duration > 0 else { return }
        libraryViewModel.seek(toProgress: time / duration)
    }

    // MARK: - Helpers

    private func formattedTime(_ time: TimeInterval) -> String {
        let total = Int(time.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Progress Section

private struct PlayerProgressSection: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        ProgressBar(
            currentTime: Binding(
                get: { currentTime },
                set: { onSeek($0) }
            ),
            duration: duration,
            onDragChanged: onSeek
        )
    }
}
