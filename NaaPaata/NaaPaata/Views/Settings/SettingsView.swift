//
//  SettingsView.swift
//  NaaPaata

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var songsViewModel: SongsViewModel
    @EnvironmentObject private var store: StoreManager

    @State private var isImporting = false
    @State private var showPaywall = false

    // Supported audio types for the document picker
    private let audioTypes: [UTType] = [
        .audio,
        .mp3,
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
                        .listRowInsets(
                            EdgeInsets(
                                top: 8,
                                leading: 16,
                                bottom: 8,
                                trailing: 16
                            )
                        )

                    } header: {

                        Text("Import")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(nil)

                    } footer: {

                        Text("Selected files will be copied into the Naa Paata sandbox folder and added to your library automatically.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                SubscriptionsView()
                    .environmentObject(store)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SongsViewModel())
        .environmentObject(StoreManager())
}
