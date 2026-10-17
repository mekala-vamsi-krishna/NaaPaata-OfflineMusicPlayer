//
//  VersionHistoryView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI

struct VersionHistoryView: View {

    // MARK: - Environment

    @EnvironmentObject private var appUpdateViewModel: AppUpdateViewModel

    // MARK: - State

    @State private var versions: [VersionInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var expandedVersions: Set<String> = []

    private let currentAppVersion: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    // MARK: - Derived

    /// The latest version in the JSON (versions are sorted descending).
    private var latestVersion: VersionInfo? {
        versions.first
    }

    /// True if the latest version in the JSON is newer than the installed app.
    private var isUpdateAvailable: Bool {
        guard let latest = latestVersion else { return false }
        return latest.version.compare(currentAppVersion, options: .numeric) == .orderedDescending
    }

    /// The version to feature at the top: latest if update available, else current.
    private var featuredVersion: VersionInfo? {
        isUpdateAvailable ? latestVersion : versions.first(where: { $0.version == currentAppVersion })
    }

    /// All versions except the featured one.
    private var olderVersions: [VersionInfo] {
        versions.filter { $0.version != featuredVersion?.version }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage {
                errorView(message: errorMessage)
            } else if versions.isEmpty {
                emptyView
            } else {
                content
            }
        }
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadVersionHistory() }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 28) {

                // Fallback hero if the installed version isn't in the list
                if featuredVersion == nil {
                    heroHeader
                }

                // Featured Card (New version or Current version)
                if let featured = featuredVersion {
                    featuredVersionCard(featured)
                }

                // Previous Releases
                if !olderVersions.isEmpty {
                    previousReleasesSection
                }

                footer
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Hero (Fallback)

    private var heroHeader: some View {
        VStack(spacing: 10) {
            // App Icon
            appIcon
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)

            Text("What's New")
                .font(.system(size: 22, weight: .bold))

            Text("You're on version \(currentAppVersion)")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Featured Version Card

    private func featuredVersionCard(_ version: VersionInfo) -> some View {
        VStack(alignment: .leading, spacing: 22) {

            // Header row
            HStack(spacing: 14) {

                // App Icon
                appIcon
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 8) {
                        Text("Version \(version.version)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)

                        // Dynamic Badge: NEW or CURRENT
                        Text(isUpdateAvailable ? "NEW" : "CURRENT")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(0.6)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                isUpdateAvailable ? Color.green : Color.accentColor,
                                in: Capsule()
                            )
                    }

                    Text(version.date)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            // Update Button
            if isUpdateAvailable {
                Button {
                    appUpdateViewModel.openAppStore()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Update Now")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(.plain)
            }

            // Release Notes
            if !version.sections.isEmpty {
                Divider()
                    .padding(.horizontal, -4)

                releaseNotes(for: version.sections)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
        )
    }

    // MARK: - Previous Releases Section

    private var previousReleasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Previous Releases")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                ForEach(Array(olderVersions.enumerated()), id: \.element.id) { index, version in

                    olderVersionRow(version)

                    if index < olderVersions.count - 1 {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func olderVersionRow(_ version: VersionInfo) -> some View {
        let isExpanded = expandedVersions.contains(version.version)

        return VStack(spacing: 0) {

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if isExpanded {
                        expandedVersions.remove(version.version)
                    } else {
                        expandedVersions.insert(version.version)
                    }
                }
            } label: {
                HStack(spacing: 12) {

                    Circle()
                        .fill(
                            isExpanded
                                ? Color.accentColor
                                : Color.secondary.opacity(0.3)
                        )
                        .frame(width: 8, height: 8)

                    Text(version.version)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(version.date)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {

                    Divider()
                        .padding(.leading, 38)

                    if version.sections.isEmpty {
                        Text("No release notes for this version.")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 38)
                            .padding(.top, 14)
                            .padding(.bottom, 18)
                    } else {
                        releaseNotes(for: version.sections)
                            .padding(.horizontal, 38)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                    }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Release Notes

    @ViewBuilder
    private func releaseNotes(for sections: VersionSections) -> some View {
        VStack(alignment: .leading, spacing: 20) {

            if !sections.newFeatures.isEmpty {
                noteSection(
                    title: "New Features",
                    icon: "sparkles",
                    color: Color.accentColor,
                    items: sections.newFeatures
                )
            }

            if !sections.enhancements.isEmpty {
                noteSection(
                    title: "Enhancements",
                    icon: "wand.and.stars",
                    color: .blue,
                    items: sections.enhancements
                )
            }

            if !sections.bugFixes.isEmpty {
                noteSection(
                    title: "Bug Fixes",
                    icon: "ladybug.fill",
                    color: .orange,
                    items: sections.bugFixes
                )
            }

            if !sections.patches.isEmpty {
                noteSection(
                    title: "Patches",
                    icon: "bandage.fill",
                    color: .purple,
                    items: sections.patches
                )
            }
        }
    }

    private func noteSection(
        title: String,
        icon: String,
        color: Color,
        items: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))

                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
            }
            .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color.opacity(0.55))
                            .frame(width: 4, height: 4)
                            .padding(.top, 8)

                        Text(item)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - App Icon Helper

    /// Loads the app icon from assets. Falls back to a colored placeholder if missing.
    @ViewBuilder
    private var appIcon: some View {
        if UIImage(named: "AppLogo") != nil {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Fallback if the asset is missing
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "music.note")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Carved with ♥")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Naa Paata · v\(currentAppVersion)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading version history…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.orange)
            }

            Text("Couldn't Load Version History")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task { await loadVersionHistory() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No Version History Available")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading

    private func loadVersionHistory() async {
        isLoading = true
        errorMessage = nil

        let result = await appUpdateViewModel.loadVersionHistory()

        switch result {
        case .success(let versions):
            self.versions = versions.sorted {
                $0.version.compare($1.version, options: .numeric) == .orderedDescending
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
