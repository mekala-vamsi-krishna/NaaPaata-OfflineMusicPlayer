//
//  PlayerContainer.swift
//  NaaPaata
//

import SwiftUI
import UIKit

// MARK: - Config

struct PlayerContainerConfig {
    var minimisedPlayerRect: CGRect = .zero
    var attachExpandedPlayer: Bool = false
    var expandPlayer: Bool = false
    var dragOffset: CGFloat = 0
    var artworkDragOffset: CGFloat = 0 // Horizontal drag for changing track by swiping
    var animation: Animation = .interpolatingSpring(
        duration: 0.3,
        bounce: 0,
        initialVelocity: 0
    )
}

// MARK: - Container

struct PlayerContainer: View {

    @Binding var config: PlayerContainerConfig
    @Namespace private var namespace

    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject private var sleepTimerManager: SleepTimerManager
    @EnvironmentObject private var progressStore: PlaybackProgressStore
    @EnvironmentObject private var folderService: DocumentFolderService

    private func artworkStep(screenWidth: CGFloat) -> CGFloat {
        let artworkSize = max(screenWidth - 48, 200)
        return artworkSize + 24
    }

    var body: some View {
        if config.attachExpandedPlayer {
            expandedPlayerView
        } else {
            miniPlayerView
        }
    }

    // MARK: - Expanded Player

    private var expandedPlayerView: some View {
        let isExpandedPlayer = config.expandPlayer
        let minimisedRect = config.minimisedPlayerRect
        let minimumRadius = minimisedRect.height / 2
        let shape = playerShape(
            minimumRadius: minimumRadius,
            isExpanded: isExpandedPlayer
        )

        return GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            let size = CGSize(
                width: proxy.size.width + safeArea.leading + safeArea.trailing,
                height: proxy.size.height + safeArea.top + safeArea.bottom
            )

            ZStack {
                if isExpandedPlayer {
                    MusicPlayerView(
                        size: size,
                        safeArea: safeArea,
                        namespace: namespace,
                        config: $config
                    )
                    .geometryGroup()
                    .transition(.opacity)
                }
            }
            .frame(
                width: isExpandedPlayer ? size.width : minimisedRect.width,
                height: isExpandedPlayer ? size.height : minimisedRect.height
            )
            .overlay(alignment: .top) {
                if !isExpandedPlayer {
                    MiniPlayerView(namespace: namespace)
                        .frame(height: minimisedRect.height)
                        .geometryGroup()
                        .transition(.opacity)
                }
            }
            .contentShape(shape)
            .clipShape(shape)
            .applyGlassEffect(in: shape)
            .visualEffect { [config] content, proxy in
                let globalRect = proxy.frame(in: .global)

                return content
                    .offset(y: config.dragOffset)
                    .offset(
                        x: isExpandedPlayer ? 0 : (minimisedRect.minX - globalRect.minX),
                        y: isExpandedPlayer ? 0 : (minimisedRect.minY - globalRect.minY)
                    )
            }
            .gesture(
                DismissGesture { translation in
                    handleDragChanged(
                        translation: translation,
                        screenWidth: size.width
                    )
                } onEnded: { velocity in
                    handleDragEnded(velocity: velocity, size: size)
                }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Mini Player

    private var miniPlayerView: some View {
        GeometryReader { proxy in
            MiniPlayerView(namespace: namespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    config.minimisedPlayerRect = proxy.frame(in: .global)
                    toggleExpandedPlayer(status: true)
                }
        }
    }

    // MARK: - Shape

    private func playerShape(
        minimumRadius: CGFloat,
        isExpanded: Bool
    ) -> AnyShape {
        if #available(iOS 26.0, *) {
            return AnyShape(
                ConcentricRectangle(
                    corners: .concentric(minimum: .fixed(minimumRadius)),
                    isUniform: true
                )
            )
        } else if isExpanded {
            return AnyShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
        } else {
            return AnyShape(
                RoundedRectangle(
                    cornerRadius: 0,
                    style: .continuous
                )
            )
        }
    }

    // MARK: - Drag Handling

    private func handleDragChanged(translation: CGPoint, screenWidth: CGFloat) {
        let h = translation.x
        let v = translation.y
        let step = artworkStep(screenWidth: screenWidth)

        if abs(h) > abs(v) {
            // Horizontal — to change the track by swiping
            config.dragOffset = 0
            config.artworkDragOffset = max(-step, min(step, h))
        } else {
            // Vertical — to close the player
            config.artworkDragOffset = 0
            config.dragOffset = max(0, v)
        }
    }

    private func handleDragEnded(velocity: CGPoint, size: CGSize) {
        let h = velocity.x
        let v = velocity.y

        if abs(h) > abs(v) {
            let step = artworkStep(screenWidth: size.width)
            let offset = config.artworkDragOffset
            let threshold = step * 0.22

            let shouldAdvance = offset < -threshold || h < -500
            let shouldGoBack  = offset >  threshold || h >  500

            if shouldAdvance {
                HapticManager.shared.light()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    config.artworkDragOffset = -step
                } completion: {
                    var t = Transaction(); t.disablesAnimations = true
                    withTransaction(t) {
                        libraryViewModel.playNext()
                        config.artworkDragOffset = 0
                    }
                }
            } else if shouldGoBack {
                HapticManager.shared.light()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    config.artworkDragOffset = step
                } completion: {
                    var t = Transaction(); t.disablesAnimations = true
                    withTransaction(t) {
                        libraryViewModel.playPrevious()
                        config.artworkDragOffset = 0
                    }
                }
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    config.artworkDragOffset = 0
                }
            }
        } else {
            let velocityY = max(v / 5, 0)
            let end = config.dragOffset + velocityY

            if end > (size.height / 2) {
                toggleExpandedPlayer(status: false)
            } else {
                withAnimation(config.animation) {
                    config.dragOffset = 0
                }
            }
        }
    }

    // MARK: - Toggle

    private func toggleExpandedPlayer(status: Bool) {
        if status {
            // Optional delay to let the glass effect complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                config.attachExpandedPlayer = true
                withAnimation(config.animation) {
                    config.expandPlayer = true
                }
            }
        } else {
            withAnimation(config.animation, completionCriteria: .removed) {
                config.dragOffset = 0
                config.expandPlayer = false
            } completion: {
                config.attachExpandedPlayer = false
                config.dragOffset = 0
            }
        }
    }
}

// MARK: - Glass Effect Helper

extension View {

    @ViewBuilder
    func applyGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Dismiss Gesture

fileprivate struct DismissGesture: UIGestureRecognizerRepresentable {

    var onChanged: (_ translation: CGPoint) -> ()
    var onEnded: (_ velocity: CGPoint) -> ()

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        return gesture
    }

    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) { }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        let state = recognizer.state
        let translation = recognizer.translation(in: recognizer.view)
        let velocity = recognizer.velocity(in: recognizer.view)

        switch state {
        case .began:
            break
        case .changed:
            onChanged(translation)
        default:
            onEnded(velocity)
        }
    }
}
