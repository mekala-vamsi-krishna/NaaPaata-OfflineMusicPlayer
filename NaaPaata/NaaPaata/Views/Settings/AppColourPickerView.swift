//
//  AppColourPickerView.swift
//  NaaPaata
//

import SwiftUI

struct AppColourPickerView: View {

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        List {
            Section {
                ForEach(AppThemeColor.all) { theme in
                    Button {
                        themeManager.setAccent(theme.id)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: theme.color.opacity(0.4), radius: 4, y: 2)

                                if isSelected(theme) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }

                            Text(theme.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            if isSelected(theme) {
                                Text("Active")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(theme.color)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("App Colour")
            } footer: {
                Text("The selected colour is applied across the entire app — buttons, icons, accents, and highlights.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Theme Colour")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isSelected(_ theme: AppThemeColor) -> Bool {
        themeManager.accentID == theme.id
    }
}
