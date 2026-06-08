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
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsVM: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager
    
    @Query(sort: \Playlist.dateCreated, order: .reverse) var playlists: [Playlist]
    
    // Create Playlist
    @State private var showCreatePlaylistSheet = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""
    
    // Sleep Timer
    @State private var showSleepTimerSheet = false
    
    // Song Info
    @State private var showSongInfoSheet = false
    
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimatingSwipeIndicator = false
    
    // Landscape mode detection
    @Environment(\.verticalSizeClass) var verticalSizeClass
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    // Dynamic sizing
    @State private var artworkScale: CGFloat = 1.0
    @State private var artworkColors: (background: Color, primary: Color, secondary: Color) = (
        background: Color(red: 0.05, green: 0.05, blue: 0.12),
        primary: AppColors.primary,
        secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
    )
    
    var body: some View {
        ZStack {
            // Premium Blended Gradient Background
            GeometryReader { geometry in
                ZStack {
                    // Base gradient that adapts to theme
                    if colorScheme == .dark {
                        // Dark mode gradient
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
                        // Light mode gradient
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
                    
                    // Artwork-based blurred overlay (only visible in dark mode)
                    if colorScheme == .dark, let artwork = musicPlayerManager.artworkImage {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .opacity(0.15)
                            .blur(radius: 60)
                            .scaleEffect(1.2)
                    }
                    
                    // Smooth top-to-bottom blur transition using multiple layers
                    if colorScheme == .dark {
                        // Top blur - lighter
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            .opacity(0.4)
                            .mask(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Bottom blur - darker
                        VisualEffectBlur(blurStyle: .systemMaterialDark)
                            .opacity(0.6)
                            .mask(
                                LinearGradient(
                                    colors: [Color.white.opacity(0), Color.white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        // Light mode blurs
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
                            .opacity(0.3)
                            .mask(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        VisualEffectBlur(blurStyle: .systemMaterialLight)
                            .opacity(0.4)
                            .mask(
                                LinearGradient(
                                    colors: [Color.white.opacity(0), Color.white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    extractArtworkColors()
                }
                .onChange(of: musicPlayerManager.currentSong) { _, _ in
                    extractArtworkColors()
                }
            }
            .ignoresSafeArea()
            
            // Main Content
            if isLandscape {
                landscapeContent
            } else {
                portraitContent
            }
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
        
        // Sample colors from artwork for dynamic background
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
    
    // MARK: - Portrait Content
    private var portraitContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Swipe Down Indicator
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
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimatingSwipeIndicator
                )
                .onAppear {
                    isAnimatingSwipeIndicator = true
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dismiss()
                    }
                }
                
                Spacer(minLength: 0)
                
                // Circular Album Artwork
                VStack(spacing: 20) {
                    CircularAlbumArtwork(
                        artwork: musicPlayerManager.artworkImage,
                        size: min(geometry.size.width * 0.7, 320),
                        isPlaying: musicPlayerManager.isPlaying,
                        colorScheme: colorScheme
                    )
                    .scaleEffect(artworkScale)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            artworkScale = artworkScale == 1.0 ? 0.98 : 1.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    artworkScale = 1.0
                                }
                            }
                        }
                    }
                    
                    // Song Info
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
                }
                
                Spacer(minLength: 0)
                
                // Banner Ad - Positioned above controls in portrait
                if geometry.size.width > 0 && geometry.size.width.isFinite {
                    let adWidth = min(max(geometry.size.width - 40, 200), 320)
                    if adWidth > 0 && adWidth.isFinite {
                        BannerAdView(adUnitID: AddsKeys.addUnitId.rawValue)
                            .frame(width: adWidth, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                    }
                }
                
                // Bottom Controls Section
                VStack(spacing: 20) {
                    // Top row with sleep timer and menu
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Sleep Timer Button
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
                            
                            // Menu Button
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
                    
                    // Main Playback Controls with Shuffle left and Repeat right
                    HStack(spacing: 0) {
                        // Shuffle Button (Left)
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
                        
                        // Previous, Play/Pause, Next
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
                        
                        // Repeat Button (Right)
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
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(y: dragOffset)
            .gesture(dragGesture)
        }
    }

    // MARK: - Landscape Content
    private var landscapeContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Section - Album Artwork with Banner Ad Below
                VStack(spacing: 16) {
                    Spacer(minLength: 0)
                    
                    CircularAlbumArtwork(
                        artwork: musicPlayerManager.artworkImage,
                        size: min(geometry.size.height * 0.55, 300),
                        isPlaying: musicPlayerManager.isPlaying,
                        colorScheme: colorScheme
                    )
                    
                    // Banner Ad - Positioned below artwork in landscape
                    if geometry.size.width > 0 && geometry.size.width.isFinite {
                        let adWidth = min(max(geometry.size.width * 0.3, 180), 250)
                        if adWidth > 0 && adWidth.isFinite {
                            BannerAdView(adUnitID: AddsKeys.addUnitId.rawValue)
                                .frame(width: adWidth, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                
                // Right Section - Controls
                VStack(spacing: 20) {
                    Spacer(minLength: 0)
                    
                    // Top Right Controls
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
                    .padding(.trailing, 24)
                    
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
                        // Shuffle Button
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
                        
                        // Previous, Play/Pause, Next
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
                        
                        // Repeat Button
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
                    
                    Spacer(minLength: 0)
                        .frame(height: max(geometry.safeAreaInsets.bottom, 20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(y: dragOffset)
            .gesture(dragGesture)
        }
    }
    
    private var repeatIconName: String {
        switch musicPlayerManager.currentRepeatMode {
        case .off:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
    
    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 100 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
    
    @State private var rotationAngle: Double = 0
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            // Outer glow ring
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
            
            // Main artwork container
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
                                .rotationEffect(.degrees(isRotating ? rotationAngle : 0))
                                .onChange(of: isPlaying) { _, newValue in
                                    if newValue {
                                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                                            rotationAngle = 360
                                            isRotating = true
                                        }
                                    } else {
                                        withAnimation(.linear(duration: 0.3)) {
                                            isRotating = false
                                        }
                                    }
                                }
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
}

// MARK: - Progress Bar
struct ProgressBar: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onDragChanged: (TimeInterval) -> Void
    let colorScheme: ColorScheme
    
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.12))
                        .frame(height: 3)
                    
                    // Filled portion
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
                    
                    // Draggable circle
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
                            
                            // Update the player position as user drags
                            onDragChanged(newTime)
                        }
                        .onEnded { value in
                            isDragging = false
                            let newPosition = max(0, min(geometry.size.width, value.location.x))
                            let progress = newPosition / geometry.size.width
                            let newTime = progress * duration
                            currentTime = newTime
                            
                            // Update the player position when drag ends
                            onDragChanged(newTime)
                        }
                )
            }
            .frame(height: 30)
            
            // Time labels
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

#Preview {
    MusicPlayerView()
        .environmentObject(MusicPlayerManager.shared)
        .environmentObject(PlaylistsViewModel())
}
