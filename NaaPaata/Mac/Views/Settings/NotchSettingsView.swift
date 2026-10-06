//
//  NotchSettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/24/26.
//

import SwiftUI

struct NotchSettingsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    @EnvironmentObject private var store: StoreManager

    @AppStorage("showNotchMedia") private var showNotchMedia = false

    var body: some View {
        Form {
            Section {
                premiumRow
            } footer: {
                Text("Displays playback controls at the top center of your screen. Macs without a physical notch get a simulated one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: Live preview
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    NotchPreviewCard()
                        .frame(maxWidth: .infinity)

                    if !store.isPremimumUser {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.accentColor)

                            Text("Available with Naa Paata +")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Notch")
    }

    // MARK: - Premium row

    @ViewBuilder
    private var premiumRow: some View {
        if store.isPremimumUser {
            Toggle("Show Media in Notch", isOn: $showNotchMedia)
                .onChange(of: showNotchMedia) { _, newValue in
                    if newValue {
                        NotchWindowController.shared.show(viewModel: viewModel)
                    } else {
                        NotchWindowController.shared.hide()
                    }
                }
        } else {
            HStack(spacing: 10) {
                Text("Show Media in Notch")
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Circle()
                        .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                        .frame(width: 28, height: 28)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor.opacity(0.9))
                }
            }
            .help("Available with Naa Paata +")
        }
    }
}


// MARK: - Preview

#Preview {
    NotchPreviewCard()
        .padding(24)
        .frame(width: 520, height: 300)
        .background(Color(nsColor: .windowBackgroundColor))
}


