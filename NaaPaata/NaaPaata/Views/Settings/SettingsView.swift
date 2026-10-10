//
//  SettingsView.swift
//  NaaPaata
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {

    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var libraryViewModel: MusicLibraryViewModel

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
        List {
            // MARK: - Import
            Section {
                Button {
                    AudioDocumentPicker.present(allowedTypes: audioTypes) { urls in
                        guard !urls.isEmpty else { return }
                        isImporting = true
                        Task {
                            await libraryViewModel.importSongs(from: urls)
                            await MainActor.run {
                                isImporting = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 14) {
                        iconTile(systemName: "folder.fill", tint: .accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import from Files")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)

                            Text("Copy audio files into Naa Paata")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isImporting {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .disabled(isImporting)
            } header: {
                sectionHeader("Import")
            } footer: {
                Text("Selected files will be copied into the Naa Paata sandbox folder and added to your library automatically.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // MARK: - Appearance
            Section {
                NavigationLink {
                    AppThemePickerView()
                } label: {
                    SettingsRow(
                        icon: "sun.max.fill",
                        title: "App Theme",
                        subtitle: "Light, Dark, or System",
                        tintColor: themeManager.accent
                    ) {
                        Text(themeManager.colorScheme.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    AppColourPickerView()
                } label: {
                    SettingsRow(
                        icon: "paintpalette.fill",
                        title: "App Colour",
                        subtitle: "Choose your app accent colour",
                        tintColor: themeManager.accent
                    ) {
                        Circle()
                            .fill(themeManager.accent)
                            .frame(width: 16, height: 16)
                            .shadow(color: themeManager.accent.opacity(0.4), radius: 3)
                    }
                }
            } header: {
                sectionHeader("Appearance & Customisation")
            }

            // MARK: - Support & Feedback
            Section {
                Button {
                    rateApp()
                } label: {
                    SettingsRow(
                        icon: "star.fill",
                        title: "Rate on App Store",
                        tintColor: .accentColor
                    ) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    sendFeedback()
                } label: {
                    SettingsRow(
                        icon: "envelope.open.fill",
                        title: "Provide your feedback",
                        tintColor: .accentColor
                    ) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                sectionHeader("Support & Feedback")
            }

            // MARK: - About
            Section {
                NavigationLink {
                    VersionHistoryView()
                } label: {
                    SettingsRow(
                        icon: "clock.arrow.circlepath",
                        title: "Version History",
                        tintColor: .accentColor
                    ) {
                        EmptyView()
                    }
                }

                NavigationLink {
                    AboutView()
                } label: {
                    SettingsRow(
                        icon: "info.circle",
                        title: "About Naa Paata",
                        tintColor: .accentColor
                    ) {
                        EmptyView()
                    }
                }
            } header: {
                sectionHeader("About")
            } footer: {
                Text("Carved Naa Paata with ♥")
                    .font(.subheadline)
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }

            // MARK: - Premium
            if !store.isPremimumUser {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 14) {
                            iconTile(systemName: "crown.fill", tint: .yellow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock Premium")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)

                                Text("Equalizer, enhanced audio & more")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Premium")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            SubscriptionsView()
                .environmentObject(store)
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    // MARK: - Icon tile

    private func iconTile(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(tint.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
        }
    }

    // MARK: - Actions

    private func rateApp() {
        let appID = "6755621058"
        guard let url = URL(string: "https://apps.apple.com/sa/app/naa-paata-music-player/id\(appID)") else {
            return
        }
        UIApplication.shared.open(url)
    }

    private func sendFeedback() {
        let email = "techpalle2026@gmail.com"
        let subject = "Feedback about Naa Paata"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let body = "App Version: \(version)\n\n\n"

        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") else {
            return
        }
        UIApplication.shared.open(url)
    }
}
