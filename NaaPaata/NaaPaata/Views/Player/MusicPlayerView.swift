//
//  MusicPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import SwiftData

struct MusicPlayerView: View {
    // MARK: - Dependencies
    let dismissAction: (() -> Void)?
    let miniPlayerFrame: CGRect
    let namespace: Namespace.ID

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsVM: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @Query(sort: \Playlist.dateCreated, order: .reverse) var playlists: [Playlist]

    // MARK: - State
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""
    
    @State private var showCreatePlaylistSheet = false
    @State private var showSleepTimerSheet = false
    @State private var showSongInfoSheet = false
    @State private var isAnimatingSwipeIndicator = false
    
    @State private var dragOffset: CGFloat = 0
    @State private var artworkScale: CGFloat = 1.0

    @State private var artworkColors: (background: Color, primary: Color, secondary: Color) = (
        background: Color(red: 0.05, green: 0.05, blue: 0.12),
        primary: AppColors.primary,
        secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
    )

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    private var maxDragOffset: CGFloat {
        UIScreen.main.bounds.height * 0.25
    }
    
    private var dragProgress: CGFloat {
        let progress = min(1, dragOffset / maxDragOffset)
        return max(0, progress)
    }

    private var artworkDragScale: CGFloat {
        let fullSize = min(UIScreen.main.bounds.width * 0.7, 320)
        let miniSize = 48.0
        let targetScale = miniSize / fullSize
        return 1 - (1 - targetScale) * dragProgress
    }
    
    private var artworkDragTranslation: CGSize {
        guard miniPlayerFrame != .zero else { return .zero }
        let fullCenter = CGPoint(x: UIScreen.main.bounds.width / 2,
                                 y: UIScreen.main.bounds.height / 2)
        let targetCenter = CGPoint(x: miniPlayerFrame.midX,
                                   y: miniPlayerFrame.midY)
        let delta = CGSize(width: (targetCenter.x - fullCenter.x) * dragProgress,
                           height: (targetCenter.y - fullCenter.y) * dragProgress)
        return delta
    }
    
    private var backgroundOpacity: CGFloat {
        let progress = min(1, dragOffset / maxDragOffset)
        return 1 - progress * 0.8
    }

    private var contentOpacity: CGFloat {
        let progress = min(1, dragOffset / maxDragOffset)
        return 1 - progress * 0.7
    }
    
    private var repeatIconName: String {
        switch musicPlayerManager.currentRepeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height
                if translation < maxDragOffset {
                    dragOffset = translation
                } else {
                    let extra = translation - maxDragOffset
                    dragOffset = maxDragOffset + extra * 0.15
                }
                if dragOffset < -20 { dragOffset = -20 }
            }
            .onEnded { value in
                let crossedThreshold = value.translation.height > maxDragOffset * 0.6
                let flungDown = value.predictedEndTranslation.height > maxDragOffset * 1.2
                
                if crossedThreshold || flungDown {
                    dismissAction?()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Methods
    private func extractArtworkColors() {
        guard let artwork = musicPlayerManager.artworkImage else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let colors = artwork.getDominantColors()
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if colorScheme == .dark {
                        artworkColors = (
                            background: colors.background,
                            primary: colors.primary,
                            secondary: colors.secondary
                        )
                    } else {
                        artworkColors = (
                            background: colors.background.opacity(0.2),
                            primary: colors.primary.opacity(0.1),
                            secondary: colors.secondary.opacity(0.05)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            GeometryReader { geometry in
                ZStack {
                    (colorScheme == .dark ? Color.black : Color.white)
                                .ignoresSafeArea()
                    
                    // Base gradient
                    if colorScheme == .dark {
                        LinearGradient(
                            colors: [
                                artworkColors.background,
                                artworkColors.secondary,
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                artworkColors.background.opacity(0.3),
                                Color.white.opacity(0.95),
                                Color.white
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                    // Artwork-based blurred overlay
                    if colorScheme == .dark, let artwork = musicPlayerManager.artworkImage {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .opacity(0.15)
                            .blur(radius: 60)
                            .scaleEffect(1.2)
                    }

                    // Blur layers
                    if colorScheme == .dark {
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            .opacity(0.4)
                            .mask(LinearGradient(colors: [Color.white, Color.white.opacity(0)], startPoint: .top, endPoint: .bottom))
                        VisualEffectBlur(blurStyle: .systemMaterialDark)
                            .opacity(0.6)
                            .mask(LinearGradient(colors: [Color.white.opacity(0), Color.white], startPoint: .top, endPoint: .bottom))
                    } else {
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
                            .opacity(0.3)
                            .mask(LinearGradient(colors: [Color.white, Color.white.opacity(0)], startPoint: .top, endPoint: .bottom))
                        VisualEffectBlur(blurStyle: .systemMaterialLight)
                            .opacity(0.4)
                            .mask(LinearGradient(colors: [Color.white.opacity(0), Color.white], startPoint: .top, endPoint: .bottom))
                    }
                }
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .onAppear { extractArtworkColors() }
                .onChange(of: musicPlayerManager.currentSong) { _, _ in extractArtworkColors() }
            }
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            // Main content – entire view moves with drag
            Group {
                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
            .offset(y: dragOffset)
            .gesture(dragGesture)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCreatePlaylistSheet) {
            CreatePlaylistSheet(
                name: $newPlaylistName,
                description: $newPlaylistDescription,
                onCreate: { coverImage in
                    playlistsVM.addPlaylist(name: newPlaylistName, description: newPlaylistDescription, coverImage: coverImage, playlists: playlists)
                    if let currentSong = musicPlayerManager.currentSong,
                       let newPlayList = PlaylistManager.shared.loadPlaylist(name: newPlaylistName) {
                        playlistsVM.addSongToPlaylist(currentSong, to: newPlayList)
                    }
                    newPlaylistName = ""
                    newPlaylistDescription = ""
                    showCreatePlaylistSheet = false
                }
            )
        }
        .sheet(isPresented: $showSongInfoSheet) {
            if let song = musicPlayerManager.currentSong {
                NavigationStack {
                    SongInfoView(song: song)
                }
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showSleepTimerSheet) {
            SleepTimerPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Portrait Content (Artwork perfectly centered)
    private var portraitContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    Text("Swipe down")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
                .offset(y: isAnimatingSwipeIndicator ? 5 : -5)
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimatingSwipeIndicator)
                .onAppear { isAnimatingSwipeIndicator = true }
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dismissAction?()
                    }
                }

                VStack(spacing: 20) {
                    CircularAlbumArtwork(
                        artwork: musicPlayerManager.artworkImage,
                        size: min(geometry.size.width * 0.7, 320),
                        isPlaying: musicPlayerManager.isPlaying,
                        colorScheme: colorScheme,
                    )
                    .scaleEffect(artworkDragScale)
                    .offset(artworkDragTranslation)
                    .scaleEffect(artworkScale)

                    VStack(spacing: 6) {
                        Text(musicPlayerManager.currentSong?.title ?? "Unknown Title")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        Text(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 32)
                    .opacity(contentOpacity)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 12) {
                    // Banner Ad
                    if geometry.size.width > 0 && geometry.size.width.isFinite {
                        let adWidth = min(max(geometry.size.width - 40, 200), 320)
                        if adWidth > 0 && adWidth.isFinite {
                            BannerAdView(adUnitID: AddsKeys.addUnitId.rawValue)
                                .frame(width: adWidth, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(12)
                                .opacity(contentOpacity)
                        }
                    }

                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            HStack(spacing: 16) {
                                Button(action: {
                                    HapticManager.shared.light()
                                    showSleepTimerSheet = true
                                }) {
                                    ZStack {
                                        Image(systemName: sleepTimerManager.isTimerActive ? "moon.fill" : "moon")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(sleepTimerManager.isTimerActive ? AppColors.primary : (colorScheme == .dark ? .white : .black))
                                            .frame(width: 40, height: 40)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                        if sleepTimerManager.isTimerActive {
                                            Text(sleepTimerManager.formattedTimeRemaining)
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(AppColors.primary)
                                                .clipShape(Capsule())
                                                .offset(x: 14, y: -14)
                                        }
                                    }
                                }

                                Menu {
                                    Button {
                                        showSongInfoSheet = true
                                    } label: {
                                        Label("Song Info", systemImage: "info.circle")
                                    }
                                    Divider()
                                    ForEach(playlists) { playlist in
                                        Button {
                                            if let currentSong = musicPlayerManager.currentSong {
                                                playlistsVM.addSongToPlaylist(currentSong, to: playlist)
                                            }
                                        } label: {
                                            if let currentSong = musicPlayerManager.currentSong,
                                               playlist.songs.contains(where: { $0.relativePath == currentSong.relativePath }) {
                                                Label(playlist.name, systemImage: "checkmark")
                                            } else {
                                                Label(playlist.name, systemImage: "music.note.list")
                                            }
                                        }
                                    }
                                    Divider()
                                    Button {
                                        showCreatePlaylistSheet = true
                                    } label: {
                                        Label("Create New Playlist", systemImage: "plus.circle")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Progress Bar
                        ProgressBar(
                            currentTime: $musicPlayerManager.currentTime,
                            duration: musicPlayerManager.duration,
                            onDragChanged: { time in
                                musicPlayerManager.seek(to: time)
                            },
                            colorScheme: colorScheme
                        )
                        .padding(.horizontal, 24)

                        // Playback Controls
                        HStack(spacing: 0) {
                            ControlButton(
                                icon: "shuffle",
                                isActive: musicPlayerManager.shuffleIsActive,
                                action: {
                                    HapticManager.shared.medium()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        musicPlayerManager.toggleShuffle()
                                    }
                                },
                                colorScheme: colorScheme
                            )
                            .frame(width: 50)

                            Spacer()

                            HStack(spacing: 30) {
                                Button(action: {
                                    HapticManager.shared.light()
                                    musicPlayerManager.playPrevious()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 50, height: 50)
                                }

                                PlayPauseButton(
                                    isPlaying: musicPlayerManager.isPlaying,
                                    size: 70,
                                    action: {
                                        HapticManager.shared.medium()
                                        musicPlayerManager.togglePlayPause()
                                    },
                                    colorScheme: colorScheme
                                )

                                Button(action: {
                                    HapticManager.shared.light()
                                    musicPlayerManager.playNext()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: 50, height: 50)
                                }
                            }

                            Spacer()

                            ControlButton(
                                icon: repeatIconName,
                                isActive: musicPlayerManager.currentRepeatMode != .off,
                                action: {
                                    HapticManager.shared.medium()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        musicPlayerManager.cycleRepeatMode()
                                    }
                                },
                                colorScheme: colorScheme
                            )
                            .frame(width: 50)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                    .opacity(contentOpacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Landscape Content (artwork centered vertically on left)
    private var landscapeContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Artwork (centered vertically)
                VStack {
                    Spacer()
                    CircularAlbumArtwork(
                        artwork: musicPlayerManager.artworkImage,
                        size: min(geometry.size.width * 0.55, 300),
                        isPlaying: musicPlayerManager.isPlaying,
                        colorScheme: colorScheme,
                    )
                    .scaleEffect(artworkDragScale)
                    .offset(artworkDragTranslation)
                    .scaleEffect(artworkScale)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Right: Controls
                VStack(spacing: 20) {
                    Spacer()

                    // Top row: Ad banner on left, buttons on right
                    HStack {
                        // Banner Ad – with geometry-based sizing and horizontal padding
                        if geometry.size.width > 0 && geometry.size.width.isFinite {
                            let adWidth = min(max(geometry.size.width * 0.25, 160), 220)
                            if adWidth > 0 && adWidth.isFinite {
                                BannerAdView(adUnitID: AddsKeys.addUnitId.rawValue)
                                    .frame(width: adWidth, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .opacity(contentOpacity)
                            }
                        }

                        Spacer(minLength: 8)

                        // Sleep timer & menu buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                HapticManager.shared.light()
                                showSleepTimerSheet = true
                            }) {
                                ZStack {
                                    Image(systemName: sleepTimerManager.isTimerActive ? "moon.fill" : "moon")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(sleepTimerManager.isTimerActive ? AppColors.primary : (colorScheme == .dark ? .white : .black))
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                    if sleepTimerManager.isTimerActive {
                                        Text(sleepTimerManager.formattedTimeRemaining)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(AppColors.primary)
                                            .clipShape(Capsule())
                                            .offset(x: 14, y: -14)
                                    }
                                }
                            }

                            Menu {
                                Button {
                                    showSongInfoSheet = true
                                } label: {
                                    Label("Song Info", systemImage: "info.circle")
                                }
                                Divider()
                                ForEach(playlists) { playlist in
                                    Button {
                                        if let currentSong = musicPlayerManager.currentSong {
                                            playlistsVM.addSongToPlaylist(currentSong, to: playlist)
                                        }
                                    } label: {
                                        if let currentSong = musicPlayerManager.currentSong,
                                           playlist.songs.contains(where: { $0.relativePath == currentSong.relativePath }) {
                                            Label(playlist.name, systemImage: "checkmark")
                                        } else {
                                            Label(playlist.name, systemImage: "music.note.list")
                                        }
                                    }
                                }
                                Divider()
                                Button {
                                    showCreatePlaylistSheet = true
                                } label: {
                                    Label("Create New Playlist", systemImage: "plus.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)   // Aligns with the other controls

                    // Song Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(musicPlayerManager.currentSong?.title ?? "Unknown Title")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(1)
                        Text(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentOpacity)

                    // Progress Bar
                    ProgressBar(
                        currentTime: $musicPlayerManager.currentTime,
                        duration: musicPlayerManager.duration,
                        onDragChanged: { time in
                            musicPlayerManager.seek(to: time)
                        },
                        colorScheme: colorScheme
                    )
                    .padding(.horizontal, 24)
                    .opacity(contentOpacity)

                    // Playback Controls
                    HStack(spacing: 0) {
                        ControlButton(
                            icon: "shuffle",
                            isActive: musicPlayerManager.shuffleIsActive,
                            action: {
                                HapticManager.shared.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicPlayerManager.toggleShuffle()
                                }
                            },
                            colorScheme: colorScheme
                        )
                        .frame(width: 50)

                        Spacer()

                        HStack(spacing: 30) {
                            Button(action: {
                                HapticManager.shared.light()
                                musicPlayerManager.playPrevious()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }

                            PlayPauseButton(
                                isPlaying: musicPlayerManager.isPlaying,
                                size: 70,
                                action: {
                                    HapticManager.shared.medium()
                                    musicPlayerManager.togglePlayPause()
                                },
                                colorScheme: colorScheme
                            )

                            Button(action: {
                                HapticManager.shared.light()
                                musicPlayerManager.playNext()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }
                        }

                        Spacer()

                        ControlButton(
                            icon: repeatIconName,
                            isActive: musicPlayerManager.currentRepeatMode != .off,
                            action: {
                                HapticManager.shared.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicPlayerManager.cycleRepeatMode()
                                }
                            },
                            colorScheme: colorScheme
                        )
                        .frame(width: 50)
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentOpacity)

                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.bottom, 20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
