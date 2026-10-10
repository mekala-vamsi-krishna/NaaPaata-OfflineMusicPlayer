//
//  EQBandColumn.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

struct EQBandColumn: View {
    @ObservedObject var viewModel: EqualizerViewModel
    let index: Int
    let band: EQBand
    let height: CGFloat

    @State private var isHovering = false
    @State private var showDetail = false

    private let dbRange: ClosedRange<Double> = -12...12

    private var isEnabled: Bool { band.isEnabled && viewModel.isEnabled }

    var body: some View {
        GeometryReader { geo in
            let trackHeight = geo.size.height
            let knobY = yPosition(for: band.gain, height: trackHeight)

            ZStack {
                // Track
                Capsule()
                    .fill(Color.primary.opacity(0.10))
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)

                // Fill from 0 dB to knob
                fill(trackHeight: trackHeight, knobY: knobY)

                // Knob
                knob(knobY: knobY)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let t = 1 - (value.location.y / trackHeight)
                        let db = dbRange.lowerBound + Double(t) * (dbRange.upperBound - dbRange.lowerBound)
                        viewModel.setGain(db, at: index)
                    }
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
            .contextMenu {
                Button("Reset to 0 dB") { viewModel.resetBand(at: index) }
                Button(band.isEnabled ? "Disable band" : "Enable band") {
                    viewModel.toggleBand(at: index)
                }
                Divider()
                Button("Show detail…") { showDetail = true }
            }
            .popover(isPresented: $showDetail, arrowEdge: .bottom) {
                BandDetailPopover(viewModel: viewModel, index: index)
            }
        }
    }

    // MARK: - Fill

    @ViewBuilder
    private func fill(trackHeight: CGFloat, knobY: CGFloat) -> some View {
        let midY = trackHeight / 2
        let top = min(knobY, midY)
        let fillH = abs(knobY - midY)

        if fillH > 0.5 {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: band.gain >= 0
                            ? [.accentColor, .accentColor.opacity(0.6)]
                            : [Color.orange.opacity(0.7), Color.orange.opacity(0.4)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 3, height: fillH)
                .position(x: 0, y: 0)
                .offset(x: 0, y: top + fillH / 2)
                .opacity(isEnabled ? 1 : 0.4)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Knob

    @ViewBuilder
    private func knob(knobY: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.background)
                .frame(width: 16, height: 16)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)

            Circle()
                .strokeBorder(
                    isEnabled ? Color.accentColor : Color.gray.opacity(0.5),
                    lineWidth: 2
                )
                .frame(width: 16, height: 16)

            // Hover value readout
            if isHovering {
                Text(String(format: "%+.1f", band.gain))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
                    .offset(y: -22)
                    .transition(.opacity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .offset(y: knobY - 8)
        .opacity(isEnabled ? 1 : 0.5)
    }

    // MARK: - Helpers

    private func yPosition(for gain: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(gain, dbRange.lowerBound), dbRange.upperBound)
        let t = (clamped - dbRange.lowerBound) / (dbRange.upperBound - dbRange.lowerBound)
        return height * CGFloat(1 - t)
    }
}

// MARK: - Detail popover

struct BandDetailPopover: View {
    @ObservedObject var viewModel: EqualizerViewModel
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: "%.0f Hz", viewModel.bands[index].frequency))
                .font(.headline)

            HStack {
                Text("Gain")
                Spacer()
                TextField(
                    "0.0",
                    value: Binding(
                        get: { viewModel.bands[index].gain },
                        set: { viewModel.setGain($0, at: index) }
                    ),
                    format: .number.precision(.fractionLength(1))
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .multilineTextAlignment(.trailing)
                Text("dB").foregroundStyle(.secondary)
            }

            HStack {
                Text("Q")
                Spacer()
                TextField(
                    "1.0",
                    value: Binding(
                        get: { viewModel.bands[index].q },
                        set: { viewModel.setQ($0, at: index) }
                    ),
                    format: .number.precision(.fractionLength(1))
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .multilineTextAlignment(.trailing)
            }
            .disabled(!viewModel.parametricMode)

            Divider()

            HStack {
                Button("Reset") { viewModel.resetBand(at: index) }
                Spacer()
                Button(viewModel.bands[index].isEnabled ? "Disable" : "Enable") {
                    viewModel.toggleBand(at: index)
                }
            }
            .controlSize(.small)
        }
        .padding(14)
        .frame(width: 220)
    }
}
