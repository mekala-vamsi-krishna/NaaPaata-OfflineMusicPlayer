//
//  MusicPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI

struct MusicPlayerView: View {
    // MARK: - Dependencies
    let dismissAction: () -> Void
    var namespace: Namespace.ID

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @EnvironmentObject var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject var playlistsVM: PlaylistsViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager
    @EnvironmentObject var albumsViewModel: AlbumsViewModel

    // MARK: - State
    @State private var showAddToPlaylistSheet = false
    @State private var showSleepTimerSheet = false
    @State private var showSongInfoSheet = false
    @State private var showAlbumSheet = false

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var repeatIconName: String {
        switch musicPlayerManager.currentRepeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Dark Blurred Artwork Background
            GeometryReader { geometry in
                ZStack {
                    if let artwork = musicPlayerManager.artworkImage {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .scaleEffect(1.2)
                            .blur(radius: 80)
                            .overlay(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.3), Color.black.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Color.black
                    }
                }
                .ignoresSafeArea()
            }
            .ignoresSafeArea()

            // Main content – with drag to dismiss
            Group {
                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.velocity.height
                        if translation > 80 || velocity > 300 {
                            dismissAction()
                        }
                    }
            )
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddToPlaylistSheet) {
            if let currentSong = musicPlayerManager.currentSong {
                AddToPlaylistView(song: currentSong)
                    .environmentObject(musicPlayerManager)
            }
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
        .sheet(isPresented: $showAlbumSheet) {
            if let currentSong = musicPlayerManager.currentSong {
                let matched = albumsViewModel.albums.first(where: { $0.name == currentSong.album })
                NavigationStack {
                    AlbumDetailsView(
                        title: matched?.name ?? currentSong.album,
                        artwork: matched?.artworkImage ?? currentSong.artworkImage,
                        songs: matched?.songs ?? [currentSong]
                    )
                    .navigationTitle(matched?.name ?? currentSong.album)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: - Portrait Content
    private var portraitContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Dismiss indicator
                VStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Swipe down")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .onTapGesture {
                    dismissAction()
                }

                Spacer(minLength: 8)

                // Artwork – larger
                let artworkSize = min(geometry.size.width * 0.82, 380)
                if let artwork = musicPlayerManager.artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: artworkSize, height: artworkSize)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                        .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 10)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: artworkSize, height: artworkSize)
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                }

                Spacer(minLength: 16)

                // Title & artist – centred
                VStack(spacing: 6) {
                    Text(musicPlayerManager.currentSong?.title ?? "Unknown Title")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "title", in: namespace)
                        .padding(.horizontal, 32)

                    Text(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "artist", in: namespace)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 4)

                Spacer(minLength: 12)

                // Controls (progress + buttons)
                VStack(spacing: 16) {
                    // Top row: sleep timer + ellipsis menu
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            // Sleep Timer – dark theme
                            Button(action: {
                                HapticManager.shared.light()
                                showSleepTimerSheet = true
                            }) {
                                ZStack {
                                    Image(systemName: sleepTimerManager.isTimerActive ? "moon.fill" : "moon")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                    if sleepTimerManager.isTimerActive {
                                        Text(sleepTimerManager.formattedTimeRemaining)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.5))
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
                                Button {
                                    if musicPlayerManager.currentSong != nil {
                                        showAlbumSheet = true
                                    }
                                } label: {
                                    Label("Go to Album", systemImage: "square.stack")
                                }
                                Divider()
                                Button {
                                    if musicPlayerManager.currentSong != nil {
                                        showAddToPlaylistSheet = true
                                    }
                                } label: {
                                    Label("Add to Playlist", systemImage: "music.note.list")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
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
                        }
                    )
                    .padding(.horizontal, 24)

                    // Playback Controls – with spring animations
                    HStack(spacing: 0) {
                        // Shuffle
                        ControlButton(
                            icon: "shuffle",
                            isActive: musicPlayerManager.shuffleIsActive,
                            action: {
                                HapticManager.shared.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicPlayerManager.toggleShuffle()
                                }
                            }
                        )
                        .frame(width: 50)

                        Spacer()

                        HStack(spacing: 30) {
                            // Previous – no matched geometry
                            PlaybackButton(
                                icon: "backward.fill",
                                size: 28,
                                action: {
                                    HapticManager.shared.light()
                                    musicPlayerManager.playPrevious()
                                }
                            )

                            // Play/Pause – with matched geometry
                            PlaybackButton(
                                icon: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill",
                                size: 44,
                                action: {
                                    HapticManager.shared.medium()
                                    musicPlayerManager.togglePlayPause()
                                },
                                matchedGeometryID: "playButton",
                                namespace: namespace
                            )

                            // Next – with matched geometry
                            PlaybackButton(
                                icon: "forward.fill",
                                size: 28,
                                action: {
                                    HapticManager.shared.light()
                                    musicPlayerManager.playNext()
                                },
                                matchedGeometryID: "nextButton",
                                namespace: namespace
                            )
                        }

                        Spacer()

                        // Repeat
                        ControlButton(
                            icon: repeatIconName,
                            isActive: musicPlayerManager.currentRepeatMode != .off,
                            action: {
                                HapticManager.shared.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicPlayerManager.cycleRepeatMode()
                                }
                            }
                        )
                        .frame(width: 50)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))

                Spacer(minLength: 8)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Landscape Content
    private var landscapeContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Artwork (larger, centred)
                VStack {
                    Spacer()
                    let artworkSize = min(geometry.size.width * 0.5, 320)
                    if let artwork = musicPlayerManager.artworkImage {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(width: artworkSize, height: artworkSize)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .matchedGeometryEffect(id: "artwork", in: namespace)
                            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: artworkSize, height: artworkSize)
                            .matchedGeometryEffect(id: "artwork", in: namespace)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Right: Controls
                VStack(spacing: 20) {
                    Spacer()

                    // Top row: sleep timer + menu
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            // Sleep Timer – dark theme
                            Button(action: {
                                HapticManager.shared.light()
                                showSleepTimerSheet = true
                            }) {
                                ZStack {
                                    Image(systemName: sleepTimerManager.isTimerActive ? "moon.fill" : "moon")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                    if sleepTimerManager.isTimerActive {
                                        Text(sleepTimerManager.formattedTimeRemaining)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.5))
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
                                Button {
                                    if musicPlayerManager.currentSong != nil {
                                        showAlbumSheet = true
                                    }
                                } label: {
                                    Label("Go to Album", systemImage: "square.stack")
                                }
                                Divider()
                                Button {
                                    if musicPlayerManager.currentSong != nil {
                                        showAddToPlaylistSheet = true
                                    }
                                } label: {
                                    Label("Add to Playlist", systemImage: "music.note.list")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Song info – left aligned
                    VStack(alignment: .leading, spacing: 8) {
                        Text(musicPlayerManager.currentSong?.title ?? "Unknown Title")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .matchedGeometryEffect(id: "title", in: namespace)

                        Text(musicPlayerManager.currentSong?.artist ?? "Unknown Artist")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .matchedGeometryEffect(id: "artist", in: namespace)
                    }
                    .padding(.horizontal, 24)

                    // Progress Bar
                    ProgressBar(
                        currentTime: $musicPlayerManager.currentTime,
                        duration: musicPlayerManager.duration,
                        onDragChanged: { time in
                            musicPlayerManager.seek(to: time)
                        }
                    )
                    .padding(.horizontal, 24)

                    // Playback Controls – with spring animations
                    HStack(spacing: 0) {
                        // Shuffle
                        ControlButton(
                            icon: "shuffle",
                            isActive: musicPlayerManager.shuffleIsActive,
                            action: {
                                HapticManager.shared.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicPlayerManager.toggleShuffle()
                                }
                            }
                        )
                        .frame(width: 50)

                        Spacer()

                        HStack(spacing: 30) {
                            // Previous – no matched geometry
                            PlaybackButton(
                                icon: "backward.fill",
                                size: 28,
                                action: {
                                    HapticManager.shared.light()
                                    musicPlayerManager.playPrevious()
                                }
                            )

                            // Play/Pause – with matched geometry
                            PlaybackButton(
                                icon: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill",
                                size: 44,
                                action: {
                                    HapticManager.shared.medium()
                                    musicPlayerManager.togglePlayPause()
                                },
                                matchedGeometryID: "playButton",
                                namespace: namespace
                            )

                            // Next – with matched geometry
                            PlaybackButton(
                                icon: "forward.fill",
                                size: 28,
                                action: {
                                    HapticManager.shared.light()
                                    musicPlayerManager.playNext()
                                },
                                matchedGeometryID: "nextButton",
                                namespace: namespace
                            )
                        }

                        Spacer()

                        // Repeat
                        ControlButton(
                            icon: repeatIconName,
                            isActive: musicPlayerManager.currentRepeatMode != .off,
                            action: {
                                HapticManager.shared.medium()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicPlayerManager.cycleRepeatMode()
                                }
                            }
                        )
                        .frame(width: 50)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.bottom, 20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
