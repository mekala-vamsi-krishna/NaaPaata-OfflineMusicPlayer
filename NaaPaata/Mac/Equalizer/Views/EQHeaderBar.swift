//
//  EQHeaderBar.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

struct EQHeaderBar: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Binding var showSaveSheet: Bool

    var body: some View {
        HStack(spacing: 14) {

            // Universal EQ switch — this is the only on/off control.
            Toggle(isOn: $viewModel.isEnabled) {
                Text("EQ")
                    .font(.system(size: 12, weight: .semibold))
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .fixedSize()
            .help("Turn the equalizer on or off")

            Divider().frame(height: 16)

            Toggle(isOn: $viewModel.parametricMode) {
                Text("Parametric")
                    .font(.system(size: 11, weight: .medium))
            }
            .toggleStyle(.checkbox)
            .controlSize(.small)
            .fixedSize()

            Divider().frame(height: 16)

            HStack(spacing: 6) {
                Text("A/B")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()

                Picker("", selection: Binding(
                    get: { viewModel.showingB },
                    set: { $0 ? viewModel.recallB() : viewModel.recallA() }
                )) {
                    Text("A").tag(false)
                    Text("B").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 64)
                .controlSize(.mini)
                .labelsHidden()

                Menu {
                    Button("Copy current → A") { viewModel.stashToA() }
                    Button("Copy current → B") { viewModel.stashToB() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 18)
            }
            .fixedSize()

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                readout(label: "PRE",   value: String(format: "%+.1f dB", viewModel.preamp))
                readout(label: "PEAK",
                        value: String(format: "%.0f%%", viewModel.inputLevel * 100),
                        accent: viewModel.isClipping ? .red : nil)
            }
            .fixedSize()

            Divider().frame(height: 16)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.resetAll() }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Reset all bands to 0 dB")

            Button {
                showSaveSheet = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Save current curve as a preset")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(height: 42)
    }

    private func readout(label: String, value: String, accent: Color? = nil) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(accent ?? .primary)
        }
    }
}
