//
//  EditPlaylistView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import SwiftUI
import PhotosUI

struct EditPlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var playlist: Playlist
    @State private var name: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedCoverImage: UIImage?
    
    init(playlist: Binding<Playlist>) {
        _playlist = playlist
        _name = State(initialValue: playlist.wrappedValue.name)
        _selectedCoverImage = State(initialValue: playlist.wrappedValue.coverImage)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Cover Image Picker
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 160, height: 160)
                                    .overlay(
                                        Group {
                                            if let image = selectedCoverImage {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 160, height: 160)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                            } else {
                                                Image("default_playlist_cover")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 160, height: 160)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                            }
                                        }
                                    )
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Change Cover")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                            }
                            .onChange(of: selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        await MainActor.run {
                                            selectedCoverImage = image
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Name field (unchanged)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("Playlist name", text: $name)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Edit Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        playlist.name = name
                        if let newImage = selectedCoverImage {
                            playlist.coverImageData = newImage.jpegData(compressionQuality: 0.8)
                        }
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
