//
//  AppColourPickerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/28/26.
//

import SwiftUI

struct AppColourPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
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
                Section {
                    ForEach(AppThemeColor.all) { theme in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                themeManager.select(theme)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: theme.color.opacity(0.4), radius: 4, x: 0, y: 2)

                                    if themeManager.current == theme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }

                                Text(theme.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                if themeManager.current == theme {
                                    Text("Active")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.color)
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
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Theme Colour")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppColourPickerView()
}
