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
    
    // View States
    @State private var isShowingQueue = false
    @State private var isShowingLyrics = false
    
    // Lyrics States
    @State private var pastedLyrics: String = ""
    @State private var isEditingLyrics = false // ✅ Single source of truth for Edit Mode
    @FocusState private var isLyricsFocused: Bool
    
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

            // ── Main Content Switch ─────────────────────────────
            if isShowingQueue {
                compactHeader
                queueList
            } else if isShowingLyrics {
                compactHeader
                lyricsView
            } else {
                mainPlayerView
            }

            // ✅ Hide bottom controls when typing lyrics to give the editor space
            if !isLyricsFocused {
                Spacer(minLength: 16)

                // ── Playback Controls (Shared) ──────────────────────
                playbackControlsRow
                    .padding(.horizontal, 24)
                    .animation(config.animation.speed(2)) {
                        $0.opacity(config.expandPlayer ? 1 : 0)
                    }
                    .opacity(fadeIn ? 1 : 0)

                Spacer(minLength: 20)

                // ── Volume Control (Shared) ─────────────────────────
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

                Spacer(minLength: 16)

                // ── Bottom Bar: Audio Route, Lyrics, Queue ──────────
                bottomBar
                    .animation(config.animation.speed(2)) {
                        $0.opacity(config.expandPlayer ? 1 : 0)
                    }
                    .opacity(fadeIn ? 1 : 0)
                    
                Spacer(minLength: 10)
            }
        }
        .padding(.top, safeArea.top)
        .padding(.bottom, safeArea.bottom + 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            playerBackground
        }
        .onAppear {
            AppDelegate.orientationLock = .portrait
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }) {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
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
            AppDelegate.orientationLock = .allButUpsideDown
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
                   let rootVC = windowScene.keyWindow?.rootViewController {
                    rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            }
            fadeIn = false
        }
        .preferredColorScheme(.dark)
        .onChange(of: libraryViewModel.currentSong?.id) { _, _ in
            if isShowingLyrics {
                let hasLyrics = !(song?.lyrics?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                isEditingLyrics = !hasLyrics
                pastedLyrics = song?.lyrics ?? ""
            }
        }

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

    // MARK: - Main Player View

    private var mainPlayerView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Artwork(
                namespace: namespace,
                artworkSize: artworkSize,
                dragOffset: config.artworkDragOffset
            )
            .frame(width: artworkSize, height: artworkSize)

            Spacer(minLength: 30)

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
                        Button { infoSong = song } label: { Label("Info", systemImage: "info.circle") }
                        Button { showAddToPlaylist = true } label: { Label("Add to Playlist", systemImage: "music.note.list") }
                        Button { showSleepTimerSheet = true } label: {
                            if sleepTimerManager.isTimerActive {
                                Label("Timer · \(sleepTimerManager.formattedTimeRemaining)", systemImage: "moon.fill")
                            } else {
                                Label("Set Timer", systemImage: "moon.stars")
                            }
                        }
                        Divider()
                        Button(role: .destructive) { showDeleteAlert = true } label: { Label("Delete", systemImage: "trash").tint(.red) }
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

            Spacer(minLength: 20)

            PlayerProgressSection(
                currentTime: currentTime,
                duration: duration,
                onSeek: { seek(to: $0) }
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        HStack(spacing: 16) {
            Group {
                if let artworkImage {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(brandGradient)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(.white.opacity(0.35))
                        )
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .matchedGeometryEffect(id: "artwork", in: namespace)

            VStack(alignment: .leading, spacing: 2) {
                Text(song?.title ?? "Not Playing")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "title", in: namespace)

                Text(song?.artist ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "artist", in: namespace)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isShowingQueue = false
                isShowingLyrics = false
                config.isQueueOpen = false
                hideKeyboard()
            }
        }
    }

    // MARK: - Queue List

    private var queueList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(libraryViewModel.queueSnapshot, id: \.id) { queueSong in
                    let isCurrent = libraryViewModel.currentSong?.id == queueSong.id
                    
                    HStack(spacing: 12) {
                        if let data = queueSong.artworkData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(uiColor: .secondarySystemFill))
                                .frame(width: 44, height: 44)
                                .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(queueSong.title)
                                .font(.system(size: 15, weight: isCurrent ? .bold : .medium))
                                .foregroundStyle(isCurrent ? .accentColor : .white)
                                .lineLimit(1)
                            Text(queueSong.artist)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let lyrics = queueSong.lyrics, !lyrics.isEmpty {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        
                        if isCurrent && libraryViewModel.isPlaying {
                            Image(systemName: "waveform")
                                .foregroundStyle(Color.accentColor)
                                .symbolEffect(.variableColor.iterative)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        libraryViewModel.play(queueSong, in: libraryViewModel.queueSnapshot)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Lyrics View

    private var lyricsView: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    if isEditingLyrics {
                        VStack(spacing: 16) {
                            TextEditor(text: $pastedLyrics)
                                .focused($isLyricsFocused)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .frame(minHeight: 200)
                                .overlay(alignment: .topLeading) {
                                    if pastedLyrics.isEmpty {
                                        Text("Paste lyrics here...")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .padding(.horizontal, 24)
                            
                            // Action Buttons
                            HStack(spacing: 16) {
                                Button("Cancel") {
                                    cancelEditing()
                                }
                                .buttonStyle(.bordered)
                                .tint(.white.opacity(0.6))
                                
                                Button("Save Lyrics") {
                                    saveLyrics()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.accentColor)
                            }
                        }
                        .padding(.top, 20)
                        .transition(.opacity)
                        
                    } else {
                        if let lyrics = song?.lyrics, !lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(lyrics)
                                .font(.system(size: 22, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.top, 20)
                                .lineSpacing(8)
                            
                            Button {
                                startEditing(with: lyrics)
                            } label: {
                                Label("Edit Lyrics", systemImage: "pencil")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                        } else {
                            // No lyrics found
                            Text("No lyrics found")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 40)
                            
                            Button {
                                startEditing(with: "")
                            } label: {
                                Label("Add Lyrics", systemImage: "plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            let hasLyrics = !(song?.lyrics?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            if hasLyrics {
                isEditingLyrics = false
            } else {
                isEditingLyrics = true
                pastedLyrics = ""
            }
        }
    }

    // MARK: - Lyrics Helpers

    private func startEditing(with text: String) {
        pastedLyrics = text
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingLyrics = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isLyricsFocused = true
        }
    }
    
    private func cancelEditing() {
        hideKeyboard()
        pastedLyrics = song?.lyrics ?? ""
        
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingLyrics = false
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isShowingLyrics.toggle()
                    isShowingQueue = false
                    config.isQueueOpen = false
                    if !isShowingLyrics { hideKeyboard() }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isShowingLyrics ? 0.2 : 0.0))
                        .frame(width: 40, height: 40)

                    Image(systemName: "quote.bubble")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            AudioRoutePickerView()
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isShowingQueue.toggle()
                    isShowingLyrics = false
                    config.isQueueOpen = isShowingQueue
                    if !isShowingQueue { hideKeyboard() }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isShowingQueue ? 0.2 : 0.0))
                        .frame(width: 40, height: 40)

                    Image(systemName: isShowingQueue ? "xmark" : "music.note.list")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    // MARK: - Playback Controls

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
    
    private func saveLyrics() {
        if let song = song {
            do {
                try libraryViewModel.saveLyrics(pastedLyrics, for: song)
                hideKeyboard()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isEditingLyrics = false
                }
            } catch {
                print("Error saving lyrics: \(error)")
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
