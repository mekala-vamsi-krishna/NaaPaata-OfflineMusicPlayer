//
//  ContentView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/13/25.
//

import SwiftUI
import AVFoundation

struct SongsView: View {
    @EnvironmentObject var viewModel: SongsViewModel
    @EnvironmentObject var playlistsViewModel: PlaylistsViewModel
    @EnvironmentObject var tabState: TabState
    @State private var showingInstruction = false
    @State private var navigateToEqualizer = false

    var body: some View {
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
                    // Show animated dots loader during initial load
                    VStack(spacing: 20) {
                        AnimatedDotsLoader()
                        Text("Loading songs...")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        if viewModel.loadingProgress > 0 {
                            Text("\(Int(viewModel.loadingProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .transition(.opacity)
                } else if viewModel.songs.isEmpty {
                    // Empty state
                    VStack {
                        Spacer()
                        Image(systemName: "music.note.list")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(AppColors.primary).opacity(0.7)
                            .padding(.top, 50)

                        Text("Add audio files to the Naa Paata folder in the Files app to enjoy playback anytime.")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showingInstruction = true
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
                    List {
                        SongsTopBar(viewModel: viewModel) { key in
                            viewModel.currentSort = key
                            viewModel.sortSongs(by: key)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                        ForEach(viewModel.songs, id: \.self) { song in
                            Button {
                                viewModel.play(song)
                            } label: {
                                MP3FileCell(song: song)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Naa Paata ♪")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { navigateToEqualizer = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingInstruction) {
                InstructionView()
            }
            .navigationDestination(isPresented: $navigateToEqualizer) {
                EqualizerView()
            }
        }
    }
}

#Preview {
    SongsView()
}
