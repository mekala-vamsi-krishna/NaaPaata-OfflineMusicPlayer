//
//  MusicPlayerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import UIKit

struct MusicPlayerView: View {

    // MARK: - Dependencies
    let dismissAction: () -> Void
    let onDismissalProgressChanged: (CGFloat) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject var sleepTimerManager: SleepTimerManager

    // MARK: - State
    @State private var showSleepTimerSheet = false
    @GestureState private var dragTranslation: CGFloat = 0

    // MARK: - Derived

    private var song: Song? { libraryViewModel.currentSong }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var repeatIconName: String {
        libraryViewModel.repeatMode == .one ? "repeat.1" : "repeat"
    }

    private var duration: TimeInterval {
        song?.duration ?? 0
    }

    private var currentTime: TimeInterval {
        libraryViewModel.elapsed
    }

    /// Decoded artwork for the hero image and blurred background.
    private var artworkImage: UIImage? {
        guard let data = song?.artworkData else { return nil }
        return UIImage(data: data)
    }

    private var dismissalProgress: CGFloat {
        min(max(dragTranslation / 520, 0), 1)
    }

    private var playerScale: CGFloat {
        1 - (dismissalProgress * 0.055)
    }

    private var playerCornerRadius: CGFloat {
        dismissalProgress * 28
    }

    private var playerGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .updating($dragTranslation) { value, state, _ in
                guard value.translation.height > 0 else { return }
                state = value.translation.height
            }
            .onChanged { value in
                let progress = min(max(value.translation.height / 520, 0), 1)
                onDismissalProgressChanged(progress)
            }
            .onEnded { value in
                let projectedDistance = max(
                    value.translation.height,
                    value.predictedEndTranslation.height
                )
                if projectedDistance > 190 {
                    completeInteractiveDismissal()
                } else {
                    onDismissalProgressChanged(0)
                }
            }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                playerBackground

                Group {
                    if isLandscape {
                        landscapeContent
                    } else {
                        portraitContent
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(
                RoundedRectangle(cornerRadius: playerCornerRadius, style: .continuous)
            )
            .scaleEffect(playerScale, anchor: .center)
            .offset(y: max(dragTranslation, 0))
            .shadow(
                color: .black.opacity(dismissalProgress * 0.35),
                radius: dismissalProgress * 28,
                y: dismissalProgress * 12
            )
            .contentShape(Rectangle())
            .gesture(playerGesture)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .interactiveSpring(response: 0.38, dampingFraction: 0.9),
                value: dragTranslation
            )
        }
        .ignoresSafeArea()
        .background(Color.black.opacity(1 - dismissalProgress).ignoresSafeArea())
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.2)
                : .spring(response: 0.44, dampingFraction: 0.88),
            value: isLandscape
        )
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSleepTimerSheet) {
            SleepTimerPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onDisappear {
            onDismissalProgressChanged(0)
        }
    }

    private func completeInteractiveDismissal() {
        onDismissalProgressChanged(1)
        HapticManager.shared.light()
        dismissAction()
    }

    // MARK: - Background

    @ViewBuilder
    private var playerBackground: some View {
        GeometryReader { geometry in
            ZStack {
                if let artworkImage {
                    Image(uiImage: artworkImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(1.2)
                        .blur(radius: 80)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    Color.black
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Button(action: completeInteractiveDismissal) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Minimize Now Playing")
                .padding(.top, 4)

                Spacer(minLength: 8)

                let artworkSize = min(geometry.size.width * 0.82, 380)
                artworkHero(size: artworkSize)

                Spacer(minLength: 16)

                trackInfoBlock
                    .padding(.top, 4)

                Spacer(minLength: 12)

                controlsBlock
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))

                Spacer(minLength: 8)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Landscape

    private var landscapeContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack {
                    Spacer()
                    let artworkSize = min(geometry.size.width * 0.5, 320)
                    artworkHero(size: artworkSize)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 20) {
                    Spacer()

                    topActionRow
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(song?.title ?? "Unknown Title")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(song?.artist ?? "Unknown Artist")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)

                    PlayerProgressSection(
                        currentTime: currentTime,
                        duration: duration,
                        onSeek: { seek(to: $0) }
                    )
                    .padding(.horizontal, 24)

                    playbackControlsRow
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.bottom, 20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Reused pieces

    // MARK: - Artwork hero

    @ViewBuilder
    private func artworkHero(size: CGFloat) -> some View {
        if let artworkImage {
            Image(uiImage: artworkImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
        } else {
            placeholderArtwork(size: size)
        }
    }

    // MARK: - Placeholder (matches macOS)

    private func placeholderArtwork(size: CGFloat) -> some View {
        ZStack {
            brandGradient
                .grayscale(1)
                .opacity(0.35)

            Image(systemName: "music.note")
                .font(.system(size: size * 0.28, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.15), radius: 18, y: 10)
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
    
    private var trackInfoBlock: some View {
        VStack(spacing: 6) {
            Text(song?.title ?? "Unknown Title")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 32)

            Text(song?.artist ?? "Unknown Artist")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 32)
        }
    }

    private var controlsBlock: some View {
        VStack(spacing: 16) {
            topActionRow
                .padding(.horizontal, 24)

            PlayerProgressSection(
                currentTime: currentTime,
                duration: duration,
                onSeek: { seek(to: $0) }
            )
            .padding(.horizontal, 24)

            playbackControlsRow
                .padding(.horizontal, 24)
        }
    }

    private var topActionRow: some View {
        HStack {
            Spacer()

            // Sleep timer
            Button {
                HapticManager.shared.light()
                showSleepTimerSheet = true
            } label: {
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
        }
    }

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
            .frame(width: 50)

            Spacer()

            HStack(spacing: 30) {
                PlaybackButton(
                    icon: "backward.fill",
                    size: 28,
                    action: {
                        HapticManager.shared.light()
                        libraryViewModel.playPrevious()
                    }
                )

                PlaybackButton(
                    icon: libraryViewModel.isPlaying ? "pause.fill" : "play.fill",
                    size: 44,
                    action: {
                        HapticManager.shared.medium()
                        libraryViewModel.togglePlayPause()
                    }
                )

                PlaybackButton(
                    icon: "forward.fill",
                    size: 28,
                    action: {
                        HapticManager.shared.light()
                        libraryViewModel.playNext()
                    }
                )
            }

            Spacer()

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
            .frame(width: 50)
        }
    }

    // MARK: - Helpers

    private func seek(to time: TimeInterval) {
        guard duration > 0 else { return }
        libraryViewModel.seek(toProgress: time / duration)
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
