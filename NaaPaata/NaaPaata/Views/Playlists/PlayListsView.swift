//
//  PlayListsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import SwiftData

struct PlayListsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Playlist.dateCreated, order: .reverse)
    private var playlists: [Playlist]

    @State private var showAddPlaylistSheet = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistDescription = ""

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 20)
    ]

    private var service: PlaylistService {
        PlaylistService(context: modelContext)
    }

    var body: some View {
        Group {
            if playlists.isEmpty {
                emptyState
            } else {
                grid
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showAddPlaylistSheet) {
            CreatePlaylistSheet(
                name: $newPlaylistName,
                description: $newPlaylistDescription,
                onCreate: { coverImage in
                    _ = try? service.create(
                        name: newPlaylistName,
                        description: newPlaylistDescription,
                        coverImageData: coverImage?.jpegData(compressionQuality: 0.85)
                    )
                    newPlaylistName = ""
                    newPlaylistDescription = ""
                    showAddPlaylistSheet = false
                }
            )
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(playlists) { playlist in
                    NavigationLink {
                        PlaylistDetailsView(playlist: playlist)
                    } label: {
                        PlaylistCard(playlist: playlist, cardHeight: 180)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.accentColor.opacity(0.6))

            Text("No Playlists Yet")
                .font(.title2.weight(.bold))

            Text("Create your first playlist to get started")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button {
                showAddPlaylistSheet = true
            } label: {
                Label("Create Playlist", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showAddPlaylistSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accentColor)
            }
            .opacity(playlists.isEmpty ? 0 : 1)
            .disabled(playlists.isEmpty)
        }
    }
}
