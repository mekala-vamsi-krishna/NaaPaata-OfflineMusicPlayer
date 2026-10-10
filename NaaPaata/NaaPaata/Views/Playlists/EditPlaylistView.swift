//
//  EditPlaylistView.swift
//  NaaPaata
//

import SwiftUI
import PhotosUI
import SwiftData

struct EditPlaylistView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let playlist: Playlist

    @State private var name: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedCoverImage: UIImage?
    @FocusState private var isNameFocused: Bool

    init(playlist: Playlist) {
        self.playlist = playlist
        _name = State(initialValue: playlist.name)

        let existingImage: UIImage? = playlist.coverImageData
            .flatMap { UIImage(data: $0) }
        _selectedCoverImage = State(initialValue: existingImage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        coverPicker
                        nameField
                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { isNameFocused = true }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard
                        let data = try? await newItem?.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    else { return }

                    await MainActor.run {
                        selectedCoverImage = image
                    }
                }
            }
        }
    }

    // MARK: - Cover picker

    private var coverPicker: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 160, height: 160)

                        if let selectedCoverImage {
                            Image(uiImage: selectedCoverImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.secondary,
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)

                if selectedCoverImage != nil {
                    Button(action: removeImage) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 28, height: 28)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .offset(x: 8, y: -8)
                }
            }

            Text(selectedCoverImage == nil ? "Tap to add cover image" : "Tap to change")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Playlist Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Enter playlist name", text: $name)
                .focused($isNameFocused)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.primary)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {

        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(.secondary)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save", action: save)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let service = PlaylistService(context: modelContext)

        try? service.updateName(trimmed, for: playlist)
        try? service.updateCover(
            selectedCoverImage?.jpegData(compressionQuality: 0.85),
            for: playlist
        )

        dismiss()
    }

    private func removeImage() {
        selectedCoverImage = nil
        selectedItem = nil
    }
}
