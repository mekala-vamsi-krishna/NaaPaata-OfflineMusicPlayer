//
//  SettingsView.swift
//  NaaPaata

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var songsViewModel: SongsViewModel
    @EnvironmentObject private var store: StoreManager

    @State private var showFilePicker = false
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
                        Button(action: { showFilePicker = true }) {
                            HStack(spacing: 14) {
                                // Icon
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
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isImporting)
                    } header: {
                        Text("Import")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(nil)
                    } footer: {
                        Text("Selected files will be copied into the Naa Paata sandbox folder and added to your library automatically.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
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
            // File picker sheet
            .sheet(isPresented: $showFilePicker) {
                AudioDocumentPicker(allowedTypes: audioTypes) { urls in
                    guard !urls.isEmpty else { return }
                    isImporting = true
                    songsViewModel.importSongs(from: urls)
                    // Reset importing state after a short delay to let toast appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isImporting = false
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionsView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - UIDocumentPickerViewController wrapper
struct AudioDocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let onPick: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .formSheet
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void

        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick([])
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SongsViewModel())
        .environmentObject(StoreManager())
}
