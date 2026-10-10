//
//  ArtistsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI

struct ArtistsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some View {
        Group {
            if viewModel.artists.isEmpty {
                emptyState
            } else {
                artistList
            }
        }
        .navigationTitle("Artists")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Artists Yet", systemImage: "music.mic")
        } description: {
            Text("Add audio files with artist metadata to see them here.")
        }
    }

    // MARK: - List

    private var artistList: some View {
        List(viewModel.artists) { artist in
            NavigationLink(value: artist) {
                ArtistRowView(artist: artist)
            }
        }
        .listStyle(.plain)
    }
}
