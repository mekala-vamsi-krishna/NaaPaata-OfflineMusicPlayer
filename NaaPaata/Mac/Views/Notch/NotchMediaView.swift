//
//  NotchMediaView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/22/26.
//

import SwiftUI
import AppKit

struct NotchMediaView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    let geometry: NotchGeometry

    @State private var isHovering = false

    static let windowSize = CGSize(width: 520, height: 180)

    private var song: Song? { viewModel.currentSong }
    private var hasSong: Bool { song != nil }

    // MARK: - Layout

    private var isExpanded: Bool { isHovering }

    private var collapsedWidth: CGFloat { geometry.notchSize.width }
    private var collapsedHeight: CGFloat { geometry.notchSize.height }

    private var expandedWidth: CGFloat { 440 }
    private var expandedHeight: CGFloat { geometry.notchSize.height + 118 }

    private var currentWidth: CGFloat { isExpanded ? expandedWidth : collapsedWidth }
    private var currentHeight: CGFloat { isExpanded ? expandedHeight : collapsedHeight }

    private var topCurve: CGFloat { isExpanded ? 20 : 8 }
    private var bottomRadius: CGFloat { isExpanded ? 20 : 10 }

    private var expandAnimation: Animation {
        .spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.15)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {

            ZStack(alignment: .top) {

                NotchShape(topCurve: topCurve, bottomRadius: bottomRadius)
                    .fill(Color.black)
                    .frame(width: currentWidth, height: currentHeight)

                contentView
                    .frame(
                        width: currentWidth,
                        height: currentHeight,
                        alignment: .top
                    )
            }
            .clipShape(
                NotchShape(topCurve: topCurve, bottomRadius: bottomRadius)
            )

            MouseTrackingView { hovering in
                withAnimation(expandAnimation) {
                    isHovering = hovering
                }
            }
            .frame(width: currentWidth, height: currentHeight)
        }
        .frame(
            width: Self.windowSize.width,
            height: Self.windowSize.height,
            alignment: .top
        )
        .animation(expandAnimation, value: isExpanded)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if isExpanded {
            expandedContent
        } else {
            collapsedContent
        }
    }

    // MARK: - Collapsed state

    @ViewBuilder
    private var collapsedContent: some View {
        ZStack {
            if hasSong {
                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.isPlaying ? AppColor.primary : Color.white.opacity(0.5))
                        .frame(width: 5, height: 5)
                        .shadow(
                            color: viewModel.isPlaying
                                ? AppColor.primary.opacity(0.8)
                                : .clear,
                            radius: 4
                        )

                    EqualizerBars(
                        isPlaying: viewModel.isPlaying,
                        size: 13,
                        barCount: 3,
                        color: .white.opacity(0.75)
                    )
                }
            }
        }
        .frame(width: collapsedWidth, height: collapsedHeight)
    }

    // MARK: - Expanded state

    private var expandedContent: some View {
        HStack(alignment: .center, spacing: 14) {

            artworkView

            VStack(spacing: 8) {
                trackInfo
                progressRow
                transportRow
            }
            .frame(maxWidth: .infinity)

            trailingIndicator
        }
        .padding(.horizontal, 32)
        .padding(.top, geometry.notchSize.height + 14)
        .padding(.bottom, 18)
        .frame(width: expandedWidth, height: expandedHeight, alignment: .top)
    }

    // MARK: - Artwork

    private var artworkView: some View {
        ZStack {
            if let data = song?.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                        .grayscale(1)
                        .opacity(0.4)

                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 5, y: 2)
    }

    // MARK: - Track info

    @ViewBuilder
    private var trackInfo: some View {
        if let song {
            VStack(spacing: 1) {
                Text(song.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(song.artist)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
        } else {
            Text("Nothing Playing")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Progress

    @ViewBuilder
    private var progressRow: some View {
        if let song {
            HStack(spacing: 6) {
                Text(elapsedString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 30, alignment: .trailing)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.18))
                            .frame(height: 3)

                        Capsule()
                            .fill(.white)
                            .frame(
                                width: geo.size.width * viewModel.progress,
                                height: 3
                            )
                    }
                    .frame(height: 3)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 10)

                Text("-\(remainingString(for: song))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 34, alignment: .leading)
            }
            .frame(height: 10)
        } else {
            Capsule()
                .fill(.white.opacity(0.12))
                .frame(height: 3)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Transport

    private var transportRow: some View {
        HStack(spacing: 24) {
            transportButton(
                systemName: "backward.fill",
                size: 13,
                enabled: hasSong,
                action: viewModel.playPrevious
            )

            transportButton(
                systemName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: 17,
                enabled: true,
                action: {
                    if hasSong {
                        viewModel.togglePlayPause()
                    } else {
                        startLibraryPlayback()
                    }
                }
            )
            .contentTransition(.symbolEffect(.replace))

            transportButton(
                systemName: "forward.fill",
                size: 13,
                enabled: hasSong,
                action: viewModel.playNext
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func transportButton(
        systemName: String,
        size: CGFloat,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.white.opacity(enabled ? 1.0 : 0.35))
                .frame(width: 30, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    // MARK: - Trailing indicator

    @ViewBuilder
    private var trailingIndicator: some View {
        if hasSong {
            EqualizerBars(
                isPlaying: viewModel.isPlaying,
                size: 22,
                barCount: 4,
                color: .white
            )
            .opacity(viewModel.isPlaying ? 1 : 0.35)
        } else {
            Color.clear.frame(width: 22, height: 22)
        }
    }

    // MARK: - Helpers

    private var elapsedString: String {
        let total = Int(viewModel.elapsed.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func remainingString(for song: Song) -> String {
        guard let duration = song.duration, duration > 0 else { return "0:00" }
        let remaining = max(duration - viewModel.elapsed, 0)
        let total = Int(remaining.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func startLibraryPlayback() {
        guard !viewModel.songs.isEmpty else { return }
        viewModel.playAll(viewModel.songs)
    }
}
