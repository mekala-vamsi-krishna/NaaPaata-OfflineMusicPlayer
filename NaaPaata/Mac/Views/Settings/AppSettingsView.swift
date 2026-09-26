//
//  AppSettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct AppSettingsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    @EnvironmentObject private var appearanceService: AppearanceService

    @State private var selection: SettingsCategory? = .appearance
    @State private var path: [SettingsCategory] = []

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(width: 760, height: 520)
        .onChange(of: selection) { _, _ in
            path.removeAll()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(SettingsCategory.allCases, selection: $selection) { category in
            Label(category.title, systemImage: category.systemImage)
                .tag(category)
        }
        .listStyle(.sidebar)
        .frame(width: 210)
    }

    // MARK: - Detail

    private var detail: some View {
        NavigationStack(path: $path) {
            rootPane(for: selection ?? .appearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Root of the current category

    @ViewBuilder
    private func rootPane(for category: SettingsCategory) -> some View {
        switch category {

        case .appearance:
            AppearanceSettingsView(service: appearanceService)

        case .notch:
            NotchSettingsView(viewModel: viewModel)

        case .stats:
            StatsSettingsView()

        case .library:
            LibrarySettingsView(viewModel: viewModel)

        case .audioEngine:
            PlaceholderSettingsView(
                category: .audioEngine,
                message: "Audio engine preferences are coming in a future update."
            )

        case .about:
            AboutSettingsView()
        }
    }
}
