//
//  LibrarySettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/24/26.
//

import SwiftUI

struct LibrarySettingsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some View {
        Form {

            // MARK: - Folder

            Section("Naa Paata Folder") {
                LabeledContent("Location") {
                    Text(viewModel.libraryFolderURL.path)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.trailing)
                }

                HStack(spacing: 10) {
                    Button {
                        viewModel.revealLibraryInFinder()
                    } label: {
                        Label("Reveal in Finder", systemImage: "finder")
                    }

                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("Rescan Library", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 4)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }

            // MARK: - Storage

            Section("Storage") {
                LabeledContent("Total Size") {
                    Text(viewModel.formattedLibrarySize)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }

                LabeledContent("Songs") {
                    Text("\(viewModel.songs.count)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }

                LabeledContent("Average File Size") {
                    Text(viewModel.formattedAverageFileSize)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Library")
    }
}
