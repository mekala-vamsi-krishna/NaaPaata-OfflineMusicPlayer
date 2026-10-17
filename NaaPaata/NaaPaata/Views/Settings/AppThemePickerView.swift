//
//  AppearanceModePickerView.swift
//  NaaPaata
//

import SwiftUI

struct AppearanceModePickerView: View {

    @EnvironmentObject private var appearanceManager: AppearanceManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0.95),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            List {
                Section {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button {
                            guard mode != appearanceManager.mode else { return }
                            performThemeTransition(to: mode)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(modeColor(mode).opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(modeColor(mode))
                                }

                                Text(mode.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)

                                Spacer()

                                if appearanceManager.mode == mode {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("App Theme")
                } footer: {
                    Text("Light and Dark override the system setting. System follows your device's appearance automatically.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("App Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modeColor(_ mode: AppearanceMode) -> Color {
        switch mode {
        case .system: return Color.accentColor
        case .light:  return Color.orange
        case .dark:   return Color.indigo
        }
    }
}
