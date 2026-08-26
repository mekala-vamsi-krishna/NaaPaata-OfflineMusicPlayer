//
//  PlaybackDetailsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI

// MARK: - Custom Stepped Slider

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
        uiView.tintColor = UIColor(tintColor)
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

// MARK: - SteppedSlider with Dots and Labels

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
                ZStack(alignment: .leading) {
                    SteppedSlider(value: $value, range: range, step: step, steps: steps, tintColor: tintColor)
                        .frame(height: 30)
                        .frame(width: geometry.size.width)

                    ForEach(steps, id: \.self) { stepValue in
                        let fraction = (stepValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                        let x = fraction * geometry.size.width
                        Circle()
                            .fill(tintColor)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: 15)
                    }
                }
                .frame(height: 30)

                ZStack(alignment: .leading) {
                    ForEach(steps.indices, id: \.self) { index in
                        let stepValue = steps[index]
                        let fraction = (stepValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                        let x = fraction * geometry.size.width
                        let isSelected = abs(value - stepValue) < 0.001
                        Text(labels[index])
                            .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? tintColor : AppColors.textSecondary.opacity(0.6))
                            .position(x: x, y: 10)
                    }
                }
                .frame(height: 20)
            }
        }
        .frame(height: 30 + 4 + 20)
        .padding(.top, 6)
    }
}

// MARK: - PlaybackDetailsView

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
