//
//  SettingsView.swift
//  NaaPaata
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {

    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var appearanceManager: AppearanceManager
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
        UTType(filenameExtension: "ogg") ?? .audio
    ]

    
    var body: some View {
        List {

            // MARK: - Music Library
            Section {
                Button {
                    AudioDocumentPicker.present(
                        allowedTypes: audioTypes
                    ) { urls in
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
                    SettingsRow(
                        icon: "folder.fill",
                        title: "Import from Files",
                        iconColor: .blue
                    ) {
                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isImporting)
            } header: {
                Text("Music Library")
            }

            // MARK: - Appearance
            Section {
                NavigationLink {
                    AppearanceModePickerView()
                } label: {
                    SettingsRow(
                        icon: "sun.max.fill",
                        title: "App Theme",
                        iconColor: .purple
                    ) {
                        Text(appearanceManager.mode.label)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Appearance")
            }

            // MARK: - Support
            Section {
                Button {
                    rateApp()
                } label: {
                    SettingsRow(
                        icon: "star.fill",
                        title: "Rate on App Store",
                        iconColor: .orange
                    ) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    sendFeedback()
                } label: {
                    SettingsRow(
                        icon: "envelope.fill",
                        title: "Provide your feedback",
                        iconColor: .green
                    ) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Support")
            }

            // MARK: - About
            Section {
                NavigationLink {
                    VersionHistoryView()
                } label: {
                    SettingsRow(
                        icon: "clock.arrow.circlepath",
                        title: "Version History",
                        iconColor: .gray
                    ) {
                        EmptyView()
                    }
                }

                NavigationLink {
                    AboutView()
                } label: {
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About Naa Paata",
                        iconColor: .cyan
                    ) {
                        EmptyView()
                    }
                }
            } header: {
                Text("About")
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
                        SettingsRow(
                            icon: "crown.fill",
                            title: "Unlock Premium",
                            iconColor: .pink
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Premium")
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

    // MARK: - Actions

    private func rateApp() {
        let appID = "6755621058"

        guard let url = URL(
            string: "https://apps.apple.com/sa/app/naa-paata-music-player/id\(appID)"
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func sendFeedback() {
        let email = "techpalle2026@gmail.com"
        let subject = "Feedback about Naa Paata"

        let version = Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "Unknown"

        let body = "App Version: \(version)\n\n\n"

        let subjectEncoded = subject.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""

        let bodyEncoded = body.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""

        guard let url = URL(
            string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }
}
