//
//  EqualizerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 11/29/25.
//

import SwiftUI

extension EqualizerView {
    private var LockedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 54))
                .foregroundColor(AppColors.primary)
            Text("Unlock Equalizer")
                .font(.title.bold())
                .foregroundColor(AppColors.textPrimary)
            Text("Subscribe to enable the Equalizer and enjoy enhanced audio quality.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 26)
            Button(action: { showPaywall = true }) {
                Text("Get Premium")
                    .font(.headline)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 26)
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .padding(.top, 4)
            .font(.subheadline)
            .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

extension EqualizerView {
    private var PremiumEqualizerContent: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [
                            AppColors.background,
                            Color(hex: "#1A1A2E"),
                            AppColors.primary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                } else {
                    Color(UIColor.systemGroupedBackground)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    // Header / Toggle
                    HStack {
                        Text("Equalizer")
                            .font(.system(size: geo.size.width > 600 ? 40 : 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.textPrimary, AppColors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()
                        Toggle("", isOn: $viewModel.isEnabled)
                            .labelsHidden()
                            .tint(AppColors.primary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: geo.size.width > 600 ? 20 : 12) {
                            // 1. Presets
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: geo.size.width > 600 ? 16 : 12) {
                                    ForEach(viewModel.presets, id: \.self) { preset in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.selectPreset(preset)
                                            }
                                        }) {
                                            Text(preset)
                                                .font(.system(size: geo.size.width > 600 ? 16 : 14, weight: viewModel.selectedPreset == preset ? .bold : .medium))
                                                .padding(.horizontal, geo.size.width > 600 ? 24 : 16)
                                                .padding(.vertical, geo.size.width > 600 ? 14 : 10)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            viewModel.selectedPreset == preset
                                                            ? AppColors.primary
                                                            : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                                                        )
                                                )
                                                .foregroundColor(
                                                    viewModel.selectedPreset == preset
                                                    ? .white
                                                    : (colorScheme == .dark ? .white : .black)
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .strokeBorder(
                                                            viewModel.selectedPreset == preset
                                                            ? AppColors.primary
                                                            : (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)),
                                                            lineWidth: viewModel.selectedPreset == preset ? 2 : 1
                                                        )
                                                )
                                                .shadow(
                                                    color: viewModel.selectedPreset == preset
                                                    ? AppColors.primary.opacity(0.3)
                                                    : Color.clear,
                                                    radius: 4,
                                                    x: 0,
                                                    y: 2
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // 2. Rotary Knobs
                            HStack(spacing: geo.size.width > 600 ? 50 : 30) {
                                RotaryKnobView(title: "Pre-Amp", value: $viewModel.preAmpValue, isEnabled: $viewModel.isPreAmpEnabled)
                                    .frame(width: geo.size.width > 600 ? 100 : 80)
                                RotaryKnobView(title: "Bass", value: $viewModel.bassValue, isEnabled: $viewModel.isBassEnabled)
                                    .frame(width: geo.size.width > 600 ? 100 : 80)
                                RotaryKnobView(title: "Treble", value: $viewModel.trebleValue, isEnabled: $viewModel.isTrebleEnabled)
                                    .frame(width: geo.size.width > 600 ? 100 : 80)
                            }
                            .padding(.horizontal)
                            .opacity(viewModel.isEnabled ? 1 : 0.5)
                            .disabled(!viewModel.isEnabled)

                            // 3. Frequency Sliders (adaptive height & width)
                            VStack(spacing: 8) {
                                Text("Frequency Bands")
                                    .font(.system(size: geo.size.width > 600 ? 18 : 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                // Determine slider height based on screen size
                                let sliderHeight: CGFloat = geo.size.width > 600 ? 220 : 160
                                let sliderWidth: CGFloat = geo.size.width > 600 ? max(40, (geo.size.width - 80) / 9) : 30

                                HStack(spacing: geo.size.width > 600 ? 16 : 12) {
                                    ForEach(0..<viewModel.bands.count, id: \.self) { index in
                                        VStack(spacing: 16) {
                                            Text("+12")
                                                .font(.system(size: geo.size.width > 600 ? 11 : 9, weight: .medium))
                                                .foregroundColor(AppColors.textSecondary.opacity(0.7))

                                            ZStack(alignment: .bottom) {
                                                Capsule()
                                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                                                    .frame(width: 4, height: sliderHeight)

                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [AppColors.primary, AppColors.primary],
                                                            startPoint: .bottom,
                                                            endPoint: .top
                                                        )
                                                    )
                                                    .frame(width: 4, height: (sliderHeight / 2) + (CGFloat(viewModel.bands[index]) * (sliderHeight / 24)))
                                                    .shadow(color: AppColors.primary.opacity(0.5), radius: 4, x: 0, y: 0)

                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: geo.size.width > 600 ? 16 : 12, height: geo.size.width > 600 ? 16 : 12)
                                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                                    .offset(y: -((sliderHeight / 2) + (CGFloat(viewModel.bands[index]) * (sliderHeight / 24))))
                                                    .padding(.bottom, 0)
                                            }
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        let y = min(max(0, sliderHeight - value.location.y), sliderHeight)
                                                        let normalized = (y / sliderHeight) * 24 - 12
                                                        viewModel.bandChanged(index: index, value: Double(normalized))
                                                    }
                                            )

                                            Text(viewModel.frequencies[index])
                                                .font(.system(size: geo.size.width > 600 ? 12 : 10, weight: .bold))
                                                .foregroundColor(AppColors.textSecondary)
                                                .rotationEffect(.degrees(geo.size.width > 600 ? 0 : -90))
                                                .frame(width: geo.size.width > 600 ? 40 : 30, height: geo.size.width > 600 ? 20 : 30)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(minWidth: sliderWidth)
                                    }
                                }
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(geo.size.width > 600 ? 24 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            )
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .opacity(viewModel.isEnabled ? 1 : 0.5)
                            .disabled(!viewModel.isEnabled)

                            // 4. Volume Control
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "speaker.fill")
                                        .font(.system(size: geo.size.width > 600 ? 20 : 16))
                                        .foregroundColor(AppColors.textSecondary)
                                    Text("Volume")
                                        .font(.system(size: geo.size.width > 600 ? 16 : 14, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text("\(Int(viewModel.volume * 100))%")
                                        .font(.system(size: geo.size.width > 600 ? 16 : 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding(.horizontal)

                                HStack(spacing: 12) {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .font(.system(size: geo.size.width > 600 ? 18 : 14))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                                    Slider(value: $viewModel.volume, in: 0...1)
                                        .tint(AppColors.primary)
                                    Image(systemName: "speaker.wave.3.fill")
                                        .font(.system(size: geo.size.width > 600 ? 18 : 14))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                                }
                                .padding(.horizontal)
                            }
                            .padding(geo.size.width > 600 ? 24 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            )
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EqualizerView: View {
    @StateObject private var viewModel = EqualizerViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var store : StoreManager
    @State private var showPaywall = false
    
    var body: some View {
        Group {
            if store.isPremimumUser {
                PremiumEqualizerContent
            } else {
                LockedView
            }
        }
        .onAppear {
            Task { await store.updateSubscriptionStatus() }
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionsView()
                .environmentObject(store)
        }
        .animation(.easeInOut, value: store.isPremimumUser)
        .navigationTitle(store.isPremimumUser ? "Equalizer" : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    EqualizerView()
}
