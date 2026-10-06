//
//  EqualizerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 11/29/25.
//

import SwiftUI

struct EqualizerView: View {

    @EnvironmentObject private var viewModel: EqualizerViewModel
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var themeManager: ThemeManager

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color { themeManager.accent }

    var body: some View {
        Group {
            if store.isPremimumUser {
                premiumContent
            } else {
                SubscriptionsView()
            }
        }
        .task {
            await store.refreshEntitlements()
        }
        .animation(.easeInOut(duration: 0.25), value: store.isPremimumUser)
        .navigationTitle(store.isPremimumUser ? "Equalizer" : "Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(store.isPremimumUser ? .visible : .hidden, for: .tabBar)
    }

    // MARK: - Premium content

    private var premiumContent: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 600

            ZStack {
                background

                VStack(spacing: 0) {
                    header(isWide: isWide)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: isWide ? 20 : 12) {
                            presetsRow(isWide: isWide)
                            knobsRow(isWide: isWide)
                            bandsSection(isWide: isWide, geo: geo)
                            volumeSection(isWide: isWide)
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(red: 0.10, green: 0.10, blue: 0.18),
                    accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        } else {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private func header(isWide: Bool) -> some View {
        HStack {
            Text("Equalizer")
                .font(.system(
                    size: isWide ? 40 : 34,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            Toggle("", isOn: $viewModel.isEnabled)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 10)
    }

    // MARK: - Presets

    private func presetsRow(isWide: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isWide ? 16 : 12) {
                ForEach(viewModel.presets, id: \.self) { preset in
                    let isSelected = viewModel.selectedPreset == preset

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectPreset(preset)
                        }
                    } label: {
                        Text(preset)
                            .font(.system(
                                size: isWide ? 16 : 14,
                                weight: isSelected ? .bold : .medium
                            ))
                            .padding(.horizontal, isWide ? 24 : 16)
                            .padding(.vertical, isWide ? 14 : 10)
                            .background(
                                Capsule().fill(
                                    isSelected
                                        ? accent
                                        : Color.primary.opacity(0.06)
                                )
                            )
                            .foregroundStyle(
                                isSelected ? .white : .primary
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected
                                        ? accent
                                        : Color.primary.opacity(0.12),
                                    lineWidth: isSelected ? 2 : 1
                                )
                            )
                            .shadow(
                                color: isSelected ? accent.opacity(0.3) : .clear,
                                radius: 4, y: 2
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Knobs

    private func knobsRow(isWide: Bool) -> some View {
        HStack(spacing: isWide ? 50 : 30) {
            RotaryKnobView(
                title: "Pre-Amp",
                value: $viewModel.preAmpValue,
                isEnabled: $viewModel.isPreAmpEnabled
            )
            .frame(width: isWide ? 100 : 80)

            RotaryKnobView(
                title: "Bass",
                value: $viewModel.bassValue,
                isEnabled: $viewModel.isBassEnabled
            )
            .frame(width: isWide ? 100 : 80)

            RotaryKnobView(
                title: "Treble",
                value: $viewModel.trebleValue,
                isEnabled: $viewModel.isTrebleEnabled
            )
            .frame(width: isWide ? 100 : 80)
        }
        .padding(.horizontal)
        .opacity(viewModel.isEnabled ? 1 : 0.5)
        .disabled(!viewModel.isEnabled)
    }

    // MARK: - Frequency bands

    private func bandsSection(isWide: Bool, geo: GeometryProxy) -> some View {
        let sliderHeight: CGFloat = isWide ? 220 : 160
        let sliderWidth: CGFloat = isWide
            ? max(40, (geo.size.width - 80) / 9)
            : 30

        return VStack(spacing: 8) {
            Text("Frequency Bands")
                .font(.system(size: isWide ? 18 : 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            HStack(spacing: isWide ? 16 : 12) {
                ForEach(0..<viewModel.bands.count, id: \.self) { index in
                    bandColumn(
                        index: index,
                        sliderHeight: sliderHeight,
                        isWide: isWide
                    )
                    .frame(minWidth: sliderWidth)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(isWide ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .padding(.horizontal)
        .padding(.top, 10)
        .opacity(viewModel.isEnabled ? 1 : 0.5)
        .disabled(!viewModel.isEnabled)
    }

    private func bandColumn(
        index: Int,
        sliderHeight: CGFloat,
        isWide: Bool
    ) -> some View {
        let value = CGFloat(viewModel.bands[index])
        let offset = (sliderHeight / 2) + (value * (sliderHeight / 24))

        return VStack(spacing: 16) {
            Text("+12")
                .font(.system(size: isWide ? 11 : 9, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.7))

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 4, height: sliderHeight)

                Capsule()
                    .fill(accent)
                    .frame(width: 4, height: offset)
                    .shadow(color: accent.opacity(0.5), radius: 4)

                Circle()
                    .fill(Color.white)
                    .frame(
                        width: isWide ? 16 : 12,
                        height: isWide ? 16 : 12
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .offset(y: -offset)
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let y = min(max(0, sliderHeight - gesture.location.y), sliderHeight)
                        let normalized = (y / sliderHeight) * 24 - 12
                        viewModel.bandChanged(
                            index: index,
                            value: Double(normalized)
                        )
                    }
            )

            Text(viewModel.frequencies[index])
                .font(.system(size: isWide ? 12 : 10, weight: .bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isWide ? 0 : -90))
                .frame(
                    width: isWide ? 40 : 30,
                    height: isWide ? 20 : 30
                )
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Volume

    private func volumeSection(isWide: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "speaker.fill")
                    .font(.system(size: isWide ? 20 : 16))
                    .foregroundStyle(.secondary)

                Text("Volume")
                    .font(.system(size: isWide ? 16 : 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(Int(viewModel.volume * 100))%")
                    .font(.system(
                        size: isWide ? 16 : 13,
                        weight: .medium,
                        design: .monospaced
                    ))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.system(size: isWide ? 18 : 14))
                    .foregroundStyle(.secondary.opacity(0.7))

                Slider(value: $viewModel.volume, in: 0...1)
                    .tint(accent)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: isWide ? 18 : 14))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .padding(.horizontal)
        }
        .padding(isWide ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
