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
                    if let url = viewModel.libraryFolderURL {
                        Text(url.path)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("No folder selected")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    // Allow the user to change the folder they selected
                    Button {
                        Task { await viewModel.selectFolder() }
                    } label: {
                        Label("Change Folder", systemImage: "folder.badge.gearshape")
                    }

                    Button {
                        viewModel.revealLibraryFolder()
                    } label: {
                        Label("Reveal in Finder", systemImage: "finder")
                    }
                    .disabled(viewModel.libraryFolderURL == nil)

                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("Rescan Library", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.libraryFolderURL == nil)

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
