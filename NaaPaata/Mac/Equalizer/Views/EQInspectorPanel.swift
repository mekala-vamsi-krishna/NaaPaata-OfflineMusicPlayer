//
//  EQInspectorPanel.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

struct EQInspectorPanel: View {
    @ObservedObject var viewModel: EqualizerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // MARK: Preamp
                section("Preamp") {
                    slider(
                        value: $viewModel.preamp,
                        range: -12...12,
                        format: { String(format: "%+.1f dB", $0) }
                    )
                }

                // MARK: Selected band
                if let selectedIdx = viewModel.bands.firstIndex(where: { $0.isEnabled }) {
                    section("Band · \(Int(viewModel.bands[selectedIdx].frequency)) Hz") {
                        VStack(alignment: .leading, spacing: 10) {
                            labeledSlider(
                                "Gain",
                                value: Binding(
                                    get: { viewModel.bands[selectedIdx].gain },
                                    set: { viewModel.setGain($0, at: selectedIdx) }
                                ),
                                range: -12...12,
                                suffix: "dB"
                            )
                            labeledSlider(
                                "Q",
                                value: Binding(
                                    get: { viewModel.bands[selectedIdx].q },
                                    set: { viewModel.setQ($0, at: selectedIdx) }
                                ),
                                range: 0.1...10,
                                suffix: ""
                            )
                            .disabled(!viewModel.parametricMode)
                        }
                    }
                }

                // MARK: Output meters
                section("Output") {
                    MeterRow(label: "Peak", value: viewModel.inputLevel,
                             clipping: viewModel.isClipping)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.8)
            content()
        }
    }

    private func slider(value: Binding<Double>, range: ClosedRange<Double>, format: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Slider(value: value, in: range)
            Text(format(value.wrappedValue))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func labeledSlider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 11, weight: .medium))
                Spacer()
                Text(String(format: "%.1f %@", value.wrappedValue, suffix))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

// MARK: - Meter

struct MeterRow: View {
    let label: String
    let value: Double
    let clipping: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(clipping ? .red : .secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.10))
                    Capsule()
                        .fill(clipping ? Color.red : Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(min(value, 1)))
                }
            }
            .frame(height: 4)
        }
    }
}
