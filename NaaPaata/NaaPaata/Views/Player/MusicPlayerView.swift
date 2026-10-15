//
//  MusicPlayerView.swift
//  NaaPaata
//

import SwiftUI
import UIKit
import SwiftData

struct MusicPlayerView: View {

    // MARK: - Dependencies

    var size: CGSize
    var safeArea: EdgeInsets
    var namespace: Namespace.ID
    @Binding var config: PlayerContainerConfig

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var folderService: DocumentFolderService
    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var sleepTimerManager: SleepTimerManager
    @EnvironmentObject private var progressStore: PlaybackProgressStore

    @Query private var favourites: [FavouriteSong]

    // MARK: - State

    @State private var showSleepTimerSheet = false
    @State private var showAddToPlaylist = false
    @State private var infoSong: Song?
    @State private var showDeleteAlert = false
    @State private var fadeIn = false
    
    // Added for the volume slider
    @State private var volume: Double = 0.5

    // MARK: - Derived

    private var song: Song? { libraryViewModel.currentSong }

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

    private var artworkImage: UIImage? {
        guard let data = song?.artworkData else { return nil }
        return UIImage(data: data)
    }

    private var artworkSize: CGFloat {
        max(size.width - 48, 200)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // ── Grabber ─────────────────────────────────────────
            Capsule()
                .fill(.white.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .animation(config.animation.speed(2)) {
                    $0.opacity(config.expandPlayer ? 1 : 0)
                }
                .opacity(fadeIn ? 1 : 0)

            Spacer(minLength: 20)

            // MARK: Artwork Carousel

            Artwork(
                namespace: namespace,
                artworkSize: artworkSize,
                dragOffset: config.artworkDragOffset
            )
            .frame(width: artworkSize, height: artworkSize)

            Spacer(minLength: 30)

            // ── Track Info & Action Buttons ──────────────────────
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song?.title ?? "Not Playing")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "title", in: namespace)

                    Text(song?.artist ?? "Unknown Artist")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "artist", in: namespace)
                }
                
                Spacer()
                
                // Action Buttons (Favourite & Ellipses)
                // Circular backgrounds to match the image exactly
                HStack(spacing: 12) {
                    Button {
                        toggleFavourite()
                    } label: {
                        Image(systemName: isCurrentSongFavourite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isCurrentSongFavourite ? .pink : .white.opacity(0.8))
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.15)))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button { infoSong = song } label: {
                            Label("Info", systemImage: "info.circle")
                        }
                        Button { showAddToPlaylist = true } label: {
                            Label("Add to Playlist", systemImage: "music.note.list")
                        }
                        Button { showSleepTimerSheet = true } label: {
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
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("Delete", systemImage: "trash").tint(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.15)))
                            .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                }
            }
            .padding(.horizontal, 24)
            .animation(config.animation.speed(2)) {
                $0.opacity(config.expandPlayer ? 1 : 0)
            }
            .opacity(fadeIn ? 1 : 0)

            Spacer(minLength: 20)

            // ── Progress Section ─────────────────────────────────
            VStack(spacing: 8) {
                PlayerProgressSection(
                    currentTime: currentTime,
                    duration: duration,
                    onSeek: { seek(to: $0) }
                )
            }
            .padding(.horizontal, 24)
            .animation(config.animation.speed(2)) {
                $0.opacity(config.expandPlayer ? 1 : 0)
            }
            .opacity(fadeIn ? 1 : 0)

            Spacer(minLength: 24)

            // ── Playback Controls ────────────────────────────────
            // Includes Shuffle, Previous, Play/Pause, Next, Repeat
            playbackControlsRow
                .padding(.horizontal, 24)
                .animation(config.animation.speed(2)) {
                    $0.opacity(config.expandPlayer ? 1 : 0)
                }
                .opacity(fadeIn ? 1 : 0)

            Spacer(minLength: 24)

            // ── Volume Control ───────────────────────────────────
            HStack(spacing: 12) {
                
                VolumeSliderView()
                    .frame(height: 30)

            }
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 24)
            .animation(config.animation.speed(2)) {
                $0.opacity(config.expandPlayer ? 1 : 0)
            }
            .opacity(fadeIn ? 1 : 0)

            Spacer(minLength: 20)
        }
        .padding(.top, safeArea.top)
        .padding(.bottom, safeArea.bottom + 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            playerBackground
        }
        .onAppear {
            // Lock the orientation policy
            AppDelegate.orientationLock = .portrait

            // Force the current window to rotate to portrait
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) {
                    
                    // Tell iOS to rotate the window NOW
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                    
                    // Tell the root VC to re-check its supported orientations
                    if let rootVC = windowScene.keyWindow?.rootViewController {
                        rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
            }

            withAnimation(config.animation.delay(0.1)) {
                fadeIn = true
            }
        }
        .onDisappear {
            // Unlock when dismissed
            AppDelegate.orientationLock = .allButUpsideDown

            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                   let rootVC = windowScene.keyWindow?.rootViewController {
                    
                    rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            }

            fadeIn = false
        }
        .preferredColorScheme(.dark)

        // MARK: - Sheets

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
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(song?.title ?? "")\" from your device?")
        }
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artwork: some View {
        if let artworkImage {
            Image(uiImage: artworkImage)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 5)
                .fill(brandGradient)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                }
        }
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
                .matchedGeometryEffect(id: "playButton", in: namespace)

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

    // MARK: - Background

    @ViewBuilder
    private var playerBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.14),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if let artworkImage {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.2)
                    .blur(radius: 80)
                    .opacity(0.55)
                    .clipped()
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

    // MARK: - Actions

    private func toggleFavourite() {
        guard let song,
              let relativePath = folderService.relativePath(for: song.url)
        else { return }

        HapticManager.shared.light()
        let service = FavouritesService(context: modelContext)
        _ = try? service.toggleFavourite(relativePath)
    }

    private func seek(to time: TimeInterval) {
        guard duration > 0 else { return }
        libraryViewModel.seek(toProgress: time / duration)
    }
    
    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else { return "0:00" }
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%d:%02d", mins, secs)
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
