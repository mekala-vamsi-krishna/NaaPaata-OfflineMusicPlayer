//
//  SettingsView.swift
//  NaaPaata

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Custom Stepped Slider (UIViewRepresentable)
struct SteppedSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let steps: [Double]
    let tintColor: Color
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.isContinuous = true
        slider.addTarget(context.coordinator,
                         action: #selector(Coordinator.valueChanged(_:)),
                         for: .valueChanged)
        slider.tintColor = UIColor(tintColor)
        return slider
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.setValue(Float(value), animated: true)
        uiView.tintColor = UIColor(AppColors.primary)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SteppedSlider

        init(_ parent: SteppedSlider) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: UISlider) {
            let rawValue = Double(sender.value)
            let steppedValue = parent.steps.min(by: { abs($0 - rawValue) < abs($1 - rawValue) }) ?? rawValue
            parent.value = steppedValue
        }
    }
}

// MARK: - SteppedSlider with Dots and Labels (Perfectly Aligned)
struct SteppedSliderWithLabels: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let labels: [String]
    let valueFormatter: (Double) -> String
    let tintColor: Color
    
    private var steps: [Double] {
        stride(from: range.lowerBound, through: range.upperBound, by: step).map { $0 }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 4) {
                // Slider + Dots
                ZStack(alignment: .leading) {
                    SteppedSlider(value: $value, range: range, step: step, steps: steps, tintColor: tintColor)
                        .frame(height: 30)
                        .frame(width: geometry.size.width)

                    // Dots at exact step positions
                    ForEach(steps, id: \.self) { stepValue in
                        let fraction = (stepValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                        let x = fraction * geometry.size.width
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: 15) // vertically centered on the slider
                    }
                }
                .frame(height: 30)

                // Labels – positioned at the exact same x coordinates
                ZStack(alignment: .leading) {
                    ForEach(steps.indices, id: \.self) { index in
                        let stepValue = steps[index]
                        let fraction = (stepValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                        let x = fraction * geometry.size.width
                        let isSelected = abs(value - stepValue) < 0.001
                        Text(labels[index])
                            .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.6))
                            .position(x: x, y: 10) // adjust vertical offset as needed
                    }
                }
                .frame(height: 20)
            }
        }
        .frame(height: 30 + 4 + 20)
        .padding(.top, 6)
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject private var songsViewModel: SongsViewModel
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @StateObject var settings = SettingsManager.shared

    @State private var isImporting = false
    @State private var showPaywall = false


    private let audioTypes: [UTType] = [
        .audio, .mp3,
        UTType(filenameExtension: "flac") ?? .audio,
        UTType(filenameExtension: "aac") ?? .audio,
        UTType(filenameExtension: "m4a") ?? .audio,
        UTType(filenameExtension: "wav") ?? .audio,
        UTType(filenameExtension: "aiff") ?? .audio,
        UTType(filenameExtension: "opus") ?? .audio,
        UTType(filenameExtension: "ogg") ?? .audio,
    ]

    var body: some View {
        NavigationStack {
            ZStack {
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

                List {
                    // MARK: - Import Section
                    Section {
                        Button {
                            AudioDocumentPicker.present(allowedTypes: audioTypes) { urls in
                                guard !urls.isEmpty else { return }
                                isImporting = true
                                songsViewModel.importSongs(from: urls)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isImporting = false
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.primary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Import from Files")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Copy audio files into Naa Paata")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                if isImporting {
                                    ProgressView()
                                        .tint(AppColors.primary)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .disabled(isImporting)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Import")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    } footer: {
                        Text("Selected files will be copied into the Naa Paata sandbox folder and added to your library automatically.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Playback Section
                    Section {
                        NavigationLink {
                            PlaybackDetailsView()
                                .environmentObject(themeManager)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.primary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "music.note")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Audio")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Crossfade, fade on Play/Pause, gapless playback")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Playback")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: - Appearance & Customisation Section
                    Section {
                        NavigationLink {
                            AppThemePickerView()
                                .environmentObject(themeManager)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.primary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("App Theme")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Light, Dark, or System")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Text(themeManager.colorScheme.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        NavigationLink {
                            AppColourPickerView()
                                .environmentObject(themeManager)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.primary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("App Colour")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Choose your app accent colour")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Circle()
                                    .fill(themeManager.current.color)
                                    .frame(width: 16, height: 16)
                                    .shadow(color: themeManager.current.color.opacity(0.4), radius: 3)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    } header: {
                        Text("Appearance & Customisation")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: - Premium Section
                    if !store.isPremimumUser {
                        Section {
                            Button(action: { showPaywall = true }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.yellow.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.yellow)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Unlock Premium")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("Equalizer, enhanced audio & more")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        } header: {
                            Text("Premium")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 60)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                SubscriptionsView()
                    .environmentObject(store)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager())
        .environmentObject(ThemeManager.shared)
}
