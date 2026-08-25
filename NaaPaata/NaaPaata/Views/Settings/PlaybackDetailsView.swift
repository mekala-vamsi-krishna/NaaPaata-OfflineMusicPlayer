//
//  PlaybackDetailsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI


struct PlaybackDetailsView: View {
    @StateObject var settings = SettingsManager.shared
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        List {
            Section {
                // Crossfade
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Crossfade")
                            .font(.headline)
                        Spacer()
                        Text(settings.crossfadeDuration == 0 ? "Off" : "\(Int(settings.crossfadeDuration)) s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    SteppedSliderWithLabels(
                        value: $settings.crossfadeDuration,
                        range: 0...12,
                        step: 3,
                        labels: ["0s", "3s", "6s", "9s", "12s"],
                        valueFormatter: { "\(Int($0)) s" },
                        tintColor: themeManager.current.color
                    )
                    .padding(.leading, 10)
                }
                .padding(.vertical, 4)

                // Fade on Play/Pause
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Fade on Play/Pause")
                            .font(.headline)
                        Spacer()
                        Text(settings.fadeDuration == 0 ? "Off" : "\(Int(settings.fadeDuration)) ms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    SteppedSliderWithLabels(
                        value: $settings.fadeDuration,
                        range: 0...1000,
                        step: 250,
                        labels: ["Off", "250", "500", "750", "1000"],
                        valueFormatter: { $0 == 0 ? "Off" : "\(Int($0)) ms" },
                        tintColor: themeManager.current.color
                    )
                    .padding(.leading, 10)
                }
                .padding(.vertical, 4)

                // Gapless Playback (toggle only)
                HStack {
                    Text("Gapless Playback")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $settings.gaplessPlayback)
                        .tint(themeManager.current.color)
                        .labelsHidden()
                }
                .padding(.vertical, 4)

            } header: {
                Text("Audio Settings")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.background.opacity(0.95),
                    AppColors.primary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Audio")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60)
        }
    }
}
