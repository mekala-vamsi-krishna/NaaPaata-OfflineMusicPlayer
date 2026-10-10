//
//  EQCanvasView.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

struct EQCanvasView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let dbRange: ClosedRange<Double> = -12...12
    private let topPadding: CGFloat = 24
    private let bottomPadding: CGFloat = 44
    private let sidePadding: CGFloat = 48

    var body: some View {
        GeometryReader { geo in
            let plotRect = CGRect(
                x: sidePadding,
                y: topPadding,
                width: geo.size.width - sidePadding * 2,
                height: geo.size.height - topPadding - bottomPadding
            )

            ZStack(alignment: .topLeading) {
                // 1. Background grid
                grid(plotRect: plotRect)

                // 2. Live spectrum (behind everything)
                SpectrumAnalyzerView(
                    bins: viewModel.spectrum,
                    color: .accentColor.opacity(colorScheme == .dark ? 0.18 : 0.12)
                )
                .frame(width: plotRect.width, height: plotRect.height)
                .offset(x: plotRect.minX, y: plotRect.minY)

                // 3. EQ curve + fill
                EQCurveView(
                    bands: viewModel.bands,
                    color: .accentColor,
                    frequencyRange: EqualizerPreset.frequencies
                )
                .frame(width: plotRect.width, height: plotRect.height)
                .offset(x: plotRect.minX, y: plotRect.minY)

                // 4. dB labels on the left
                dbLabels(plotRect: plotRect)

                // 5. Frequency labels along the bottom
                frequencyLabels(plotRect: plotRect)

                // 6. Band sliders
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.bands.enumerated()), id: \.element.id) { idx, band in
                        EQBandColumn(
                            viewModel: viewModel,
                            index: idx,
                            band: band,
                            height: plotRect.height
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, sidePadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
        }
    }

    // MARK: - Grid

    private func grid(plotRect: CGRect) -> some View {
        Canvas { ctx, _ in
            let gridColor = Color.primary.opacity(0.08)
            let zeroColor = Color.primary.opacity(0.22)

            // Horizontal — one line per 3 dB
            for db in stride(from: -12.0, through: 12.0, by: 3.0) {
                let y = yPosition(for: db, in: plotRect)
                let isZero = abs(db) < 0.001
                var path = Path()
                path.move(to: CGPoint(x: plotRect.minX, y: y))
                path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                ctx.stroke(
                    path,
                    with: .color(isZero ? zeroColor : gridColor),
                    lineWidth: isZero ? 1.0 : 0.5
                )
            }

            // Vertical — one line per band frequency
            for freq in EqualizerPreset.frequencies {
                let x = xPosition(for: freq, in: plotRect)
                var path = Path()
                path.move(to: CGPoint(x: x, y: plotRect.minY))
                path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                ctx.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Axis Labels

    private func dbLabels(plotRect: CGRect) -> some View {
        ForEach([12, 6, 0, -6, -12], id: \.self) { db in
            Text("\(db > 0 ? "+" : "")\(db)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .position(
                    x: plotRect.minX - 24,
                    y: yPosition(for: Double(db), in: plotRect)
                )
        }
    }

    private func frequencyLabels(plotRect: CGRect) -> some View {
        ForEach(Array(EqualizerPreset.frequencies.enumerated()), id: \.offset) { _, freq in
            Text(label(for: freq))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .position(
                    x: xPosition(for: freq, in: plotRect),
                    y: plotRect.maxY + 22
                )
        }
    }

    private func label(for freq: Double) -> String {
        if freq >= 1_000 {
            return "\(Int(freq / 1_000))k"
        }
        return "\(Int(freq))"
    }

    // MARK: - Coordinate helpers

    private func yPosition(for db: Double, in rect: CGRect) -> CGFloat {
        let t = (db - dbRange.lowerBound) / (dbRange.upperBound - dbRange.lowerBound)
        return rect.maxY - CGFloat(t) * rect.height
    }

    private func xPosition(for freq: Double, in rect: CGRect) -> CGFloat {
        // Logarithmic positioning across the 10 band centers.
        let freqs = EqualizerPreset.frequencies
        guard let idx = freqs.firstIndex(of: freq), freqs.count > 1 else {
            return rect.midX
        }
        let t = Double(idx) / Double(freqs.count - 1)
        return rect.minX + CGFloat(t) * rect.width
    }
}
