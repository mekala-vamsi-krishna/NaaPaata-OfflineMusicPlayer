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
    @FocusState private var isNameFocused: Bool

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
                        // MARK: - Cover Image Picker with remove button
                        VStack(spacing: 8) {
                            ZStack(alignment: .topTrailing) {
                                // Image picker
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 160, height: 160)

                                        if let image = selectedCoverImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 160, height: 160)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                        } else {
                                            Image(systemName: "music.note")
                                                .font(.system(size: 48))
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                AppColors.textSecondary,
                                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                                            )
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 20))
                                }
                                .buttonStyle(.plain)

                                // Remove button
                                if selectedCoverImage != nil {
                                    Button {
                                        removeImage()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 28, height: 28)
                                            )
                                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }

                            // Hint text
                            Text(selectedCoverImage == nil ? "Tap to add cover image" : "Tap to change")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // MARK: - Name Field
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
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Update the playlist
                        playlist.name = name

                        // Save cover image
                        if let newImage = selectedCoverImage {
                            playlist.coverImageData = newImage.jpegData(compressionQuality: 0.8)
                        } else {
                            // If user removed the image, coverImageData will be nil
                            playlist.coverImageData = nil
                        }

                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
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
    }

    // MARK: - Helpers
    private func removeImage() {
        selectedCoverImage = nil
        selectedItem = nil
    }
}
