//
//  SettingsView.swift
//  NaaPaata

import SwiftUI
import UniformTypeIdentifiers

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject private var songsViewModel: SongsViewModel
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var themeManager: ThemeManager
    
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
        NavigationStack {
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
                    // MARK: - Import Section
                    Section {
                        Button {
                            AudioDocumentPicker.present(allowedTypes: audioTypes) { urls in
                                guard !urls.isEmpty else { return }
                                isImporting = true
                                songsViewModel.importSongs(from: urls)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isImporting = false
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColors.primary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Import from Files")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("Copy audio files into Naa Paata")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                if isImporting {
                                    ProgressView()
                                        .tint(AppColors.primary)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .disabled(isImporting)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Import")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    } footer: {
                        Text("Selected files will be copied into the Naa Paata sandbox folder and added to your library automatically.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Playback Section
                    Section {
                        NavigationLink {
                            PlaybackDetailsView()
                                .environmentObject(themeManager)
                        } label: {
                            SettingsRow(
                                icon: "music.note",
                                title: "Audio",
                                subtitle: "Crossfade, fade on Play/Pause, gapless playback",
                                tintColor: themeManager.current.color
                            ) {
                                EmptyView()
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Playback")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: - Appearance & Customisation Section
                    Section {
                        NavigationLink {
                            AppThemePickerView()
                                .environmentObject(themeManager)
                        } label: {
                            SettingsRow(
                                icon: "sun.max.fill",
                                title: "App Theme",
                                subtitle: "Light, Dark, or System",
                                tintColor: themeManager.current.color
                            ) {
                                Text(themeManager.colorScheme.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        NavigationLink {
                            AppColourPickerView()
                                .environmentObject(themeManager)
                        } label: {
                            SettingsRow(
                                icon: "paintpalette.fill",
                                title: "App Colour",
                                subtitle: "Choose your app accent colour",
                                tintColor: themeManager.current.color
                            ) {
                                Circle()
                                    .fill(themeManager.current.color)
                                    .frame(width: 16, height: 16)
                                    .shadow(color: themeManager.current.color.opacity(0.4), radius: 3)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    } header: {
                        Text("Appearance & Customisation")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: - Support & Feedback Section
                    Section {
                        Button {
                            rateApp()
                        } label: {
                            SettingsRow(
                                icon: "star.fill",
                                title: "Rate on App Store",
                                tintColor: themeManager.current.color
                            ) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            sendFeedback()
                        } label: {
                            SettingsRow(
                                icon: "envelope.open.fill",
                                title: "Provide your feedback",
                                tintColor: themeManager.current.color
                            ) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)

                    } header: {
                        Text("Support & Feedback")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: - About Section
                    Section {
                        NavigationLink {
                            VersionHistoryView()
                        } label: {
                            SettingsRow(
                                icon: "clock.arrow.circlepath",
                                title: "Version History",
                                tintColor: themeManager.current.color
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
                                tintColor: themeManager.current.color
                            ) {
                                EmptyView()
                            }
                        }
                    } header: {
                        Text("About")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    } footer: {
                        VStack(spacing: 4) {
                            Text("Carved Naa Paata with ♥")
                                .font(.subheadline)
                                .fontWeight(.heavy)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    }

                    // MARK: - Premium Section
                    if !store.isPremimumUser {
                        Section {
                            Button(action: { showPaywall = true }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.yellow.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.yellow)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Unlock Premium")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("Equalizer, enhanced audio & more")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        } header: {
                            Text("Premium")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 60)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                SubscriptionsView()
                    .environmentObject(store)
            }
        }
    }

    // MARK: - rateApp

    func rateApp() {
        let appID = "6755621058"
        guard let url = URL(string: "https://apps.apple.com/sa/app/naa-paata-music-player/id\(appID)") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - sendFeedback

    func sendFeedback() {
        let email = "techpalle2026@gmail.com"
        let subject = "Feedback about Naa Paata"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let body = "App Version: \(version)\n\n\n"
        guard let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager())
        .environmentObject(ThemeManager.shared)
}
