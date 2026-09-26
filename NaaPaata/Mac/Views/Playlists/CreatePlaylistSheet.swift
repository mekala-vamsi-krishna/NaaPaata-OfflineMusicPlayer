//
//  CreatePlaylistSheet.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct CreatePlaylistSheet: View {

    var initialSongURLs: [URL] = []
    let onCreate: (_ name: String, _ description: String, _ artworkData: Data?, _ songURLs: [URL]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var artworkData: Data?
    @State private var isPickingImage = false

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            title
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 460, height: 520)
        .fileImporter(
            isPresented: $isPickingImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImagePick(result)
        }
    }

    // MARK: - Sections

    private var title: some View {
        Text("New Playlist")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                artworkPicker

                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    TextField("Playlist name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    TextField("Optional", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }

                if !initialSongURLs.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .foregroundStyle(AppColor.textSecondary)

                        Text("\(initialSongURLs.count) song\(initialSongURLs.count == 1 ? "" : "s") will be added")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)

                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
    }

    private var artworkPicker: some View {
        Button {
            isPickingImage = true
        } label: {
            ZStack {
                if let artworkData, let image = NSImage(data: artworkData) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(AppColor.textSecondary)

                        Text("Choose Photo")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColor.border)
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button("Create") {
                onCreate(name, description, artworkData, initialSongURLs)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(!canCreate)
        }
        .padding(16)
    }

    // MARK: - Image handling

    private func handleImagePick(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            if let data = try? Data(contentsOf: url) {
                artworkData = data
            }
        case .failure:
            break
        }
    }
}
