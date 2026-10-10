//
//  ArtistsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import SwiftUI

struct ArtistsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some View {
        Group {
            if viewModel.artists.isEmpty {
                EmptyStateView(
                    title: "No Artists Yet",
                    systemImage: "music.mic",
                    message: "Add audio files with artist metadata to see them here.",
                    actionTitle: "Open Library Folder",
                    action: viewModel.revealLibraryInFinder
                )
            } else {
                artistList
            }
        }
        .navigationTitle("Artists")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }

    // MARK: - List

    private var artistList: some View {
        List(viewModel.artists) { artist in
            NavigationLink(value: artist) {
                ArtistRowView(artist: artist)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.inset)
    }
}
