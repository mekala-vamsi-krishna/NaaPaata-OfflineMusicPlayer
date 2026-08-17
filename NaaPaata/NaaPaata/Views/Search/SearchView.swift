//
//  SearchView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/10/26.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var songsViewModel: SongsViewModel
    @EnvironmentObject var albumsViewModel: AlbumsViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [
                            AppColors.background,
                            AppColors.background.opacity(0.95),
                            AppColors.primary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    if searchViewModel.searchText.isEmpty {
                        // Empty prompt
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(AppColors.primary.opacity(0.5))
                            
                            Text("Search songs and albums")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    } else if searchViewModel.matchedSongs.isEmpty && searchViewModel.matchedAlbums.isEmpty {
                        // No results
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(AppColors.primary.opacity(0.5))
                            
                            Text("No results for \"\(searchViewModel.searchText)\"")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                
                                // MARK: - Songs Section
                                if !searchViewModel.matchedSongs.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Songs")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.textPrimary)
                                            .padding(.horizontal)
                                        
                                        VStack(spacing: 0) {
                                            ForEach(searchViewModel.matchedSongs, id: \.self) { song in
                                                Button {
                                                    searchViewModel.playSongFromSearchResults(song)
                                                } label: {
                                                    MP3FileCell(song: song)
                                                        .padding(.horizontal)
                                                        .padding(.vertical, 2)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                
                                // MARK: - Albums Section (now list style with chevron)
                                if !searchViewModel.matchedAlbums.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Albums")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.textPrimary)
                                            .padding(.horizontal)
                                        
                                        VStack(spacing: 0) {
                                            ForEach(searchViewModel.matchedAlbums) { album in
                                                NavigationLink {
                                                    AlbumDetailsView(
                                                        title: album.name,
                                                        artwork: album.artworkImage,
                                                        songs: album.songs
                                                    )
                                                } label: {
                                                    HStack(spacing: 14) {
                                                        // Artwork
                                                        if let artwork = album.artworkImage {
                                                            Image(uiImage: artwork)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 50, height: 50)
                                                                .cornerRadius(8)
                                                        } else {
                                                            Image(systemName: "music.note")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .padding(10)
                                                                .frame(width: 50, height: 50)
                                                                .background(AppColors.background.opacity(0.2))
                                                                .cornerRadius(8)
                                                                .foregroundColor(AppColors.primary)
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(album.name)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(AppColors.textPrimary)
                                                                .lineLimit(1)
                                                            
                                                            Text("\(album.songs.count) songs")
                                                                .font(.subheadline)
                                                                .foregroundColor(AppColors.textSecondary)
                                                                .lineLimit(1)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        // Chevron arrow
                                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 14, weight: .semibold))
                                                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                                            .padding(10)
                                                    }
                                                    .padding(.horizontal)
                                                    .padding(.vertical, 4)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .safeAreaInset(edge: .bottom) {
                                Color.clear.frame(height: 80)
                            }
                        }
                    }
                }
                .navigationTitle("Search")
                .searchable(
                    text: $searchViewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Songs, albums, artists..."
                )
                .onChange(of: searchViewModel.searchText) { _ in
                    searchViewModel.search(
                        allSongs: songsViewModel.songs,
                        allAlbums: albumsViewModel.albums
                    )
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(SearchViewModel())
        .environmentObject(AlbumsViewModel())
}
