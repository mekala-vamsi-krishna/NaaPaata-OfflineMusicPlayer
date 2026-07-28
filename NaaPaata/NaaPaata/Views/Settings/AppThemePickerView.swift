//
//  AppearanceSettingsView.swift
//  NaaPaata
//

import SwiftUI

struct AppThemePickerView: View {
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
                    ForEach(AppColorScheme.allCases) { scheme in
                        Button {
                            guard scheme != themeManager.colorScheme else { return }
                            performThemeTransition(to: scheme)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(schemeColor(scheme).opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: scheme.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(schemeColor(scheme))
                                }

                                Text(scheme.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                if themeManager.colorScheme == scheme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("App Theme")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                } footer: {
                    Text("Light and Dark override the system setting. System follows your device's appearance automatically.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("App Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func schemeColor(_ scheme: AppColorScheme) -> Color {
        switch scheme {
        case .system: return AppColors.primary
        case .light:  return Color.orange
        case .dark:   return Color.indigo
        }
    }
}
