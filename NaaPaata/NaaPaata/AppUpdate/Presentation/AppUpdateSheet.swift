//
//  AppUpdateSheet.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import SwiftUI

struct AppUpdateSheet: View {

    let info: VersionInfo
    let onDismiss: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    sections
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionButtons
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later", action: onDismiss)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {

            // App icon — loaded from the asset catalog
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 10, y: 5
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            Color.primary.opacity(0.06),
                            lineWidth: 0.5
                        )
                )

            Text("What's New")
                .font(.system(size: 26, weight: .bold))

            Text("Version \(info.version) • \(info.date)")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Sections

    @ViewBuilder
    private var sections: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !info.sections.newFeatures.isEmpty {
                UpdateSectionView(
                    title: "New Features",
                    icon: "sparkles",
                    items: info.sections.newFeatures
                )
            }

            if !info.sections.enhancements.isEmpty {
                UpdateSectionView(
                    title: "Enhancements",
                    icon: "wand.and.stars",
                    items: info.sections.enhancements
                )
            }

            if !info.sections.bugFixes.isEmpty {
                UpdateSectionView(
                    title: "Bug Fixes",
                    icon: "ladybug.fill",
                    items: info.sections.bugFixes
                )
            }

            if !info.sections.patches.isEmpty {
                UpdateSectionView(
                    title: "Patches",
                    icon: "bandage.fill",
                    items: info.sections.patches
                )
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onUpdate) {
                Text("Update Now")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Text("Maybe Later")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Section Row

private struct UpdateSectionView: View {

    let title: String
    let icon: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(item)
                            .font(.system(size: 15))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
