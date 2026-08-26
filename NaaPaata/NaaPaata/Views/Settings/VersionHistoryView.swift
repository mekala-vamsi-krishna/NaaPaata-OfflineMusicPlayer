//
//  VersionHistoryView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI

struct VersionHistoryView: View {
    @State private var versions: [Version] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    private var currentVersion: Version? {
        versions.first(where: { $0.version == currentAppVersion })
    }

    private var olderVersions: [Version] {
        versions.filter { $0.version != currentAppVersion }
    }

    var body: some View {
        Group {
            if isLoading {
                loadingStateView
            } else if let errorMessage {
                errorStateView(message: errorMessage)
            } else if versions.isEmpty {
                emptyStateView
            } else {
                List {
                    if let current = currentVersion {
                        Section {
                            currentVersionRow(version: current)
                        } header: {
                            Text("Current Version")
                        }
                    }

                    if !olderVersions.isEmpty {
                        Section {
                            ForEach(olderVersions, id: \.id) { version in
                                DisclosureGroup {
                                    releaseNotes(for: version)
                                        .padding(.top, 6)
                                        .padding(.bottom, 2)
                                } label: {
                                    HStack {
                                        Text(version.version)
                                            .font(.body.weight(.medium))
                                        Spacer()
                                        Text(version.date)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("Earlier Versions")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadVersionHistory()
        }
    }

    // MARK: - Current Version Row

    @ViewBuilder
    private func currentVersionRow(version: Version) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(version.version)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Current")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.primary, in: Capsule())

                Spacer()

                Text(version.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            releaseNotes(for: version)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Shared Release Notes

    @ViewBuilder
    private func releaseNotes(for version: Version) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            noteSection(title: "New Features", items: version.sections.newFeatures)
            noteSection(title: "Enhancements", items: version.sections.enhancements)
            noteSection(title: "Bug Fixes", items: version.sections.bugFixes)
            noteSection(title: "Patches", items: version.sections.patches)
        }
    }

    @ViewBuilder
    private func noteSection(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Loading / Error / Empty States

    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading version history…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Couldn't Load Version History")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                loadVersionHistory()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No Version History Available")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Private Methods

    private func loadVersionHistory() {
        isLoading = true
        errorMessage = nil

        if let localVersions = NetworkService.shared.loadLocalVersionHistory() {
            versions = localVersions.sorted { $0.version > $1.version }
        } else {
            errorMessage = "Could not load version history from the app bundle."
        }

        isLoading = false
    }
}
