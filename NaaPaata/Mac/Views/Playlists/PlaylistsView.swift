//
//  PlaylistsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import SwiftData

struct PlaylistsView: View {

    @Environment(\.modelContext) private var modelContext

    @ObservedObject var viewModel: MusicLibraryViewModel

    @Query(sort: \Playlist.createdAt, order: .reverse)
    private var playlists: [Playlist]

    @AppStorage("playlists.showSmartPlaylists") private var showSmartPlaylists = true

    @State private var viewMode: PlaylistViewMode = .grid
    @State private var isCreating = false

    private let gridColumns = [
        GridItem(
            .adaptive(
                minimum: PlaylistCardView.cardWidth,
                maximum: PlaylistCardView.cardWidth
            ),
            spacing: 22,
            alignment: .top
        )
    ]

    private var hasSmartPlaylists: Bool {
        !viewModel.songs.isEmpty
    }

    private var shouldShowSmartSection: Bool {
        showSmartPlaylists && hasSmartPlaylists
    }

    var body: some View {
        Group {
            if playlists.isEmpty && !shouldShowSmartSection {
                EmptyStateView(
                    title: "No Playlists Yet",
                    systemImage: "music.note.list",
                    message: "Create your first playlist to organise your music.",
                    actionTitle: "Create Playlist",
                    action: { isCreating = true }
                )
            } else {
                content
            }
        }
        .navigationTitle("Playlists")
        .sheet(isPresented: $isCreating) {
            CreatePlaylistSheet { name, description, artworkData, songURLs in
                _ = try? PlaylistService(context: modelContext).createPlaylist(
                    name: name,
                    description: description,
                    artworkData: artworkData,
                    songURLs: songURLs
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            headerBar

            switch viewMode {
            case .grid: gridContent
            case .list: listContent
            }
        }
    }

    // MARK: - Grid

    private var gridContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                if shouldShowSmartSection {
                    smartGridSection
                }

                if !playlists.isEmpty {
                    userGridSection
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var smartGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Smart Playlists")

            LazyVGrid(
                columns: gridColumns,
                alignment: .leading,
                spacing: 24
            ) {
                ForEach(SmartPlaylistKind.allCases) { kind in
                    NavigationLink(value: SmartPlaylistRoute(kind: kind)) {
                        SmartPlaylistCardView(
                            kind: kind,
                            count: SmartPlaylistDetailView
                                .resolve(kind: kind, library: viewModel.songs)
                                .count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var userGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if shouldShowSmartSection {
                sectionHeader("Your Playlists")
            }

            LazyVGrid(
                columns: gridColumns,
                alignment: .leading,
                spacing: 24
            ) {
                ForEach(playlists) { playlist in
                    NavigationLink(value: playlist) {
                        PlaylistCardView(playlist: playlist)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            try? PlaylistService(context: modelContext).delete(playlist)
                        }
                    }
                }
            }
        }
    }

    // MARK: - List

    private var listContent: some View {
        List {
            if shouldShowSmartSection {
                Section("Smart Playlists") {
                    ForEach(SmartPlaylistKind.allCases) { kind in
                        NavigationLink(value: SmartPlaylistRoute(kind: kind)) {
                            SmartPlaylistRowView(
                                kind: kind,
                                count: SmartPlaylistDetailView
                                    .resolve(kind: kind, library: viewModel.songs)
                                    .count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !playlists.isEmpty {
                Section(shouldShowSmartSection ? "Your Playlists" : "") {
                    ForEach(playlists) { playlist in
                        NavigationLink(value: playlist) {
                            PlaylistRowView(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                try? PlaylistService(context: modelContext).delete(playlist)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(AppColor.textPrimary)
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 10) {
            if hasSmartPlaylists {
                Toggle("Smart Playlists", isOn: $showSmartPlaylists)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(AppColor.primary)
            }

            Spacer()

            viewModePicker
            newPlaylistButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 1)
        }
    }

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(PlaylistViewMode.allCases, id: \.self) { mode in
                Image(systemName: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 96)
        .help("Toggle grid/list")
    }

    private var newPlaylistButton: some View {
        Button {
            isCreating = true
        } label: {
            Label("New Playlist", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .help("Create a new playlist")
    }
}
