//
//  ArtistsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import SwiftUI

struct ArtistsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    
    @State private var showHelpSheet = false

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
        .sheet(isPresented: $showHelpSheet) {
            UploadHelpSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Empty state
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.mic")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Artists Yet")
                .font(.title3.weight(.semibold))

            Text("Add audio files with artist metadata to see them here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            
            // Help Button
            Button {
                showHelpSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("How to upload songs?")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
