//
//  AlbumsView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import AVFoundation

struct AlbumsView: View {
    @EnvironmentObject var viewModel: AlbumsViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var showingOnboarding = false

    var body: some View {
        GeometryReader { geometry in
            let layout = AdaptiveLayout(
                horizontalSizeClass: sizeClass,
                screenWidth: geometry.size.width
            )
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: layout.gridSpacing),
                count: layout.gridColumns
            )

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

                    if viewModel.isLoading {
                        VStack(spacing: 20) {
                            AnimatedDotsLoader()
                            Text("Loading albums...")
                                .font(.headline)
                                .foregroundColor(AppColors.textSecondary)
                            if viewModel.loadingProgress > 0 {
                                Text("\(Int(viewModel.loadingProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .transition(.opacity)
                    } else if viewModel.albums.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "opticaldisc")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(AppColors.primary).opacity(0.7)
                                .padding(.top, 50)

                            Text("Add MP3 files to the Naa Paata folder in the Files app to enjoy playback anytime.")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                showingOnboarding = true
                            }) {
                                Text("Learn More")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primary)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 20)

                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: layout.gridSpacing) {
                                Section(header:
                                    AlbumsTopBar(
                                        viewModel: viewModel,
                                        filteredCount: viewModel.filteredAlbums.count
                                    ) { key in
                                        viewModel.currentSort = key
                                        viewModel.sortAlbums(by: key)
                                    }
                                    .padding(.horizontal, layout.horizontalPadding)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                ) {
                                    ForEach(viewModel.filteredAlbums) { album in
                                        NavigationLink {
                                            AlbumDetailsView(
                                                title: album.name,
                                                artwork: album.artworkImage,
                                                songs: album.songs
                                            )
                                        } label: {
                                            AlbumCellView(album: album, imageSize: layout.cardImageSize)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, layout.horizontalPadding)
                            .padding(.bottom, 20)
                        }
                        .overlay(
                            Group {
                                if viewModel.isRefreshing {
                                    HStack {
                                        Spacer()
                                        AnimatedDotsLoader()
                                            .scaleEffect(0.5)
                                            .padding(.trailing, 20)
                                            .padding(.top, 10)
                                    }
                                    .transition(.opacity)
                                }
                            },
                            alignment: .top
                        )
                    }
                }
                .navigationTitle("Albums")
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search albums...")
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView()
                }
            }
        }
    }
}

#Preview {
    AlbumsView()
        .environmentObject(AlbumsViewModel())
}
