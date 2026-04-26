//
//  CreatePlaylistSheet.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/5/25.
//

import SwiftUI
import PhotosUI

struct CreatePlaylistSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var name: String
    @Binding var description: String
    let onCreate: (UIImage?) -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedCoverImage: UIImage?
    @FocusState private var isNameFocused: Bool
    
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
                                    Text("Choose Cover Image")
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
                        
                        // MARK: - Name & Description (unchanged)
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Playlist Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("Enter playlist name", text: $name)
                                    .focused($isNameFocused)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(.system(size: 16))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("Add a description", text: $description, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Create Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate(selectedCoverImage)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }
}
