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
    let namespace: Namespace.ID

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsVM: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    @Query(sort: \Playlist.dateCreated, order: .reverse) var playlists: [Playlist]

    // MARK: - State
    @State private var showCreatePlaylistSheet = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""
    @State private var showSleepTimerSheet = false
    @State private var showSongInfoSheet = false

    @State private var dragOffset: CGFloat = 0
    @State private var isAnimatingSwipeIndicator = false
    @State private var artworkScale: CGFloat = 1.0

    @State private var artworkColors: (background: Color, primary: Color, secondary: Color) = (
        background: Color(red: 0.05, green: 0.05, blue: 0.12),
        primary: AppColors.primary,
        secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
    )

    // MARK: - Layout Helpers
    @Environment(\.verticalSizeClass) var verticalSizeClass
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var maxDragOffset: CGFloat {
        UIScreen.main.bounds.height * 0.25
    }

    private var backgroundOpacity: CGFloat {
        let progress = min(1, dragOffset / maxDragOffset)
        return 1 - progress * 0.8
    }

    private var artworkDragScale: CGFloat {
        let progress = min(1, dragOffset / maxDragOffset)
        return 1 - progress * 0.15
    }

    private var contentOpacity: CGFloat {
        let progress = min(1, dragOffset / maxDragOffset)
        return 1 - progress * 0.7
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

    // MARK: - Extract Artwork Colors
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
                        namespace: namespace
                    )
                    .scaleEffect(artworkDragScale)
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

                VStack(spacing: 0) {
                    // Banner Ad
                    if geometry.size.width > 0 && geometry.size.width.isFinite {
                        let adWidth = min(max(geometry.size.width - 40, 200), 320)
                        if adWidth > 0 && adWidth.isFinite {
                            BannerAdView(adUnitID: AddsKeys.addUnitId.rawValue)
                                .frame(width: adWidth, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
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
                        namespace: namespace
                    )
                    .scaleEffect(artworkDragScale)
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
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
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
}

// MARK: - UIImage Extension for Color Extraction
extension UIImage {
    func getDominantColors() -> (background: Color, primary: Color, secondary: Color) {
        guard let inputImage = CIImage(image: self) else {
            return (
                background: Color(red: 0.05, green: 0.05, blue: 0.12),
                primary: AppColors.primary,
                secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
            )
        }

        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else {
            return (
                background: Color(red: 0.05, green: 0.05, blue: 0.12),
                primary: AppColors.primary,
                secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
            )
        }

        guard let outputImage = filter.outputImage else {
            return (
                background: Color(red: 0.05, green: 0.05, blue: 0.12),
                primary: AppColors.primary,
                secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
            )
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let avgColor = Color(
            red: Double(bitmap[0]) / 255.0,
            green: Double(bitmap[1]) / 255.0,
            blue: Double(bitmap[2]) / 255.0
        )

        return (
            background: avgColor,
            primary: avgColor.opacity(0.8),
            secondary: avgColor.opacity(0.6)
        )
    }
}

// MARK: - Circular Album Artwork
struct CircularAlbumArtwork: View {
    let artwork: UIImage?
    let size: CGFloat
    let isPlaying: Bool
    let colorScheme: ColorScheme
    let namespace: Namespace.ID

    @State private var ringVisible = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1),
                            colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size + 12, height: size + 12)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(ringVisible ? 1 : 0)

            artworkCircle
                .matchedGeometryEffect(id: "albumArt", in: namespace, isSource: false)
                .transition(.identity)
        }
    }

    @ViewBuilder
    private var artworkCircle: some View {
        Circle()
            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Group {
                    if let artwork = artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: size * 0.3, weight: .thin))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
                            )
                    }
                }
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.15),
                                colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onDragChanged: (TimeInterval) -> Void
    let colorScheme: ColorScheme

    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.12))
                        .frame(height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 3)
                        .animation(.linear(duration: 0.1), value: currentTime)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 4, x: 0, y: 0)
                        .offset(x: circleXPosition(geometry: geometry), y: 0)
                        .animation(isDragging ? nil : .linear(duration: 0.1), value: currentTime)
                }
                .frame(height: 30)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newPosition = max(0, min(geometry.size.width, value.location.x))
                            let progress = newPosition / geometry.size.width
                            let newTime = progress * duration
                            currentTime = newTime
                            onDragChanged(newTime)
                        }
                        .onEnded { value in
                            isDragging = false
                            let newPosition = max(0, min(geometry.size.width, value.location.x))
                            let progress = newPosition / geometry.size.width
                            let newTime = progress * duration
                            currentTime = newTime
                            onDragChanged(newTime)
                        }
                )
            }
            .frame(height: 30)

            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
                Spacer()
                Text(formatTime(duration))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor((colorScheme == .dark ? Color.white : Color.black).opacity(0.6))
            }
        }
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return totalWidth * CGFloat(currentTime / duration)
    }

    private func circleXPosition(geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return 0 }
        let halfCircle: CGFloat = 7
        let progress = CGFloat(currentTime / duration)
        let position = progress * geometry.size.width - halfCircle
        let maxOffset = geometry.size.width - 14
        return max(0, min(maxOffset, position))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else { return "00:00" }
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - PlayPauseButton
struct PlayPauseButton: View {
    let isPlaying: Bool
    let size: CGFloat
    let action: () -> Void
    let colorScheme: ColorScheme

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.3),
                                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .scaleEffect(isPressed ? 0.92 : 1.0)

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(isPressed ? 0.92 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ControlButton
struct ControlButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    let colorScheme: ColorScheme

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isActive ? AppColors.primary : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6)))
                .frame(width: 44, height: 44)
                .background(isActive ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)) : Color.clear)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        }
    }
}

// MARK: - Visual Effect Blur
struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
