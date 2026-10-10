//
//  NotchPreviewCard.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/5/26.
//


import SwiftUI
import Combine

struct NotchPreviewCard: View {

    // MARK: - Playback simulation

    @State private var isPlaying = true
    @State private var elapsed: Double = 6
    private let totalDuration: Double = 24

    // MARK: - Expansion cycle

    @State private var isExpanded = false

    // MARK: - Dimensions (scaled down from the real panel)

    private let cardSize = CGSize(width: 460, height: 220)

    private let menuBarHeight: CGFloat = 28

    private let collapsedNotch = CGSize(width: 150, height: 28)
    private let expandedNotch  = CGSize(width: 340, height: 104)

    private var currentWidth: CGFloat {
        isExpanded ? expandedNotch.width : collapsedNotch.width
    }
    private var currentHeight: CGFloat {
        isExpanded ? expandedNotch.height : collapsedNotch.height
    }
    private var topCurve: CGFloat {
        isExpanded ? 14 : 6
    }
    private var bottomRadius: CGFloat {
        isExpanded ? 16 : 8
    }

    private var expandAnimation: Animation {
        .spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.15)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            desktopGradient
            menuBar

            // Notch sits flush with the top edge, overlapping the menu bar.
            ZStack(alignment: .top) {
                NotchShape(topCurve: topCurve, bottomRadius: bottomRadius)
                    .fill(.black)
                    .frame(width: currentWidth, height: currentHeight)

                content
                    .frame(
                        width: currentWidth,
                        height: currentHeight,
                        alignment: .top
                    )
            }
            .clipShape(NotchShape(topCurve: topCurve, bottomRadius: bottomRadius))
            .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .animation(expandAnimation, value: isExpanded)
        .onReceive(
            Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        ) { _ in
            guard isPlaying else { return }
            elapsed += 0.1
            if elapsed >= totalDuration { elapsed = 0 }
        }
        .task {
            await cycleExpansion()
        }
    }

    // MARK: - Expansion cycle

    private func cycleExpansion() async {
        // Let the user see the collapsed state first.
        try? await Task.sleep(for: .seconds(2.0))

        while !Task.isCancelled {
            withAnimation(expandAnimation) { isExpanded = true }
            try? await Task.sleep(for: .seconds(3.5))
            if Task.isCancelled { return }

            withAnimation(expandAnimation) { isExpanded = false }
            try? await Task.sleep(for: .seconds(2.0))
            if Task.isCancelled { return }
        }
    }

    // MARK: - Desktop

    private var desktopGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.09, blue: 0.28),
                Color(red: 0.22, green: 0.13, blue: 0.38),
                Color(red: 0.09, green: 0.06, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Menu bar

    private var menuBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 10, weight: .medium))
                Text("Naa Paata")
                    .font(.system(size: 10, weight: .semibold))
            }

            Spacer()

            HStack(spacing: 9) {
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                Text("4:35 PM")
                    .font(.system(size: 9.5, weight: .medium))
            }
        }
        .font(.system(size: 9))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 14)
        .frame(height: menuBarHeight)
        .background(.black.opacity(0.55))
    }

    // MARK: - Notch content

    @ViewBuilder
    private var content: some View {
        if isExpanded {
            expandedContent
        } else {
            collapsedContent
        }
    }

    // MARK: - Collapsed content

    private var collapsedContent: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(AppColor.primary)
                .frame(width: 4, height: 4)
                .shadow(color: AppColor.primary.opacity(0.9), radius: 3)

            MiniEqualizerBars(isPlaying: isPlaying, barCount: 3, size: 9)
        }
        .frame(width: collapsedNotch.width, height: collapsedNotch.height)
    }

    // MARK: - Expanded content

    private var expandedContent: some View {
        HStack(alignment: .center, spacing: 10) {

            artworkThumb

            VStack(spacing: 6) {
                trackInfo
                progressRow
                transportRow
            }
            .frame(maxWidth: .infinity)

            MiniEqualizerBars(isPlaying: isPlaying, barCount: 4, size: 16)
        }
        .padding(.horizontal, 18)
        .padding(.top, topCurve + 6)
        .padding(.bottom, 10)
        .frame(width: expandedNotch.width,
               height: expandedNotch.height,
               alignment: .top)
    }

    private var artworkThumb: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.32, blue: 0.58),
                        Color(red: 0.62, green: 0.22, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 38, height: 38)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
    }

    private var trackInfo: some View {
        VStack(spacing: 0) {
            Text("Safari")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Serena")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var progressRow: some View {
        HStack(spacing: 5) {
            Text(timeString(elapsed))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 24, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * (elapsed / totalDuration))
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 3)

            Text("-\(timeString(totalDuration - elapsed))")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 26, alignment: .leading)
        }
        .frame(height: 8)
    }

    private var transportRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "backward.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 14, height: 14)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Image(systemName: "forward.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    // MARK: - Helpers

    private func timeString(_ seconds: Double) -> String {
        let value = Int(seconds.rounded())
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}

// MARK: - Mini equalizer bars

private struct MiniEqualizerBars: View {
    let isPlaying: Bool
    let barCount: Int
    let size: CGFloat

    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(.white)
                    .frame(width: 1.5, height: barHeight(for: i))
            }
        }
        .frame(width: size, height: size, alignment: .center)
        .opacity(isPlaying ? 1 : 0.35)
        .animation(
            isPlaying
                ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                : .easeOut(duration: 0.2),
            value: phase
        )
        .onAppear { phase = 1 }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: [CGFloat] = [0.45, 0.85, 0.6, 1.0, 0.5]
        let normalized = base[index % base.count]
        return size * (isPlaying ? normalized * (0.6 + phase * 0.4) : 0.3)
    }
}

// MARK: - Preview

#Preview {
    NotchPreviewCard()
        .padding(24)
        .frame(width: 500)
        .background(Color(nsColor: .windowBackgroundColor))
}
