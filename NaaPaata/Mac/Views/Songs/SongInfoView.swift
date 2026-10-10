//
//  SongInfoView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/12/26.
//

import SwiftUI

struct SongInfoView: View {

    let song: Song

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            details
            Divider()
            footer
        }
        .frame(width: 480)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ArtworkView(data: song.artworkData, size: 84, cornerRadius: 8)
                .shadow(color: .black.opacity(0.15), radius: 5, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Text(song.artist)
                    .font(.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                Text(song.album)
                    .font(.caption)
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    private var details: some View {
        ScrollView {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                row("Title", song.title)
                row("Artist", song.artist)
                row("Album", song.album)
                row("Duration", song.formattedDuration)
                row("Date Added", dateAddedString)
                row("Format", fileFormat)
                row("Size", fileSizeString)
                row("Location", song.url.path)
            }
            .padding(20)
        }
        .frame(maxHeight: 320)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    // MARK: - Row builder

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Derived values

    private var fileFormat: String {
        let ext = song.url.pathExtension.uppercased()
        return ext.isEmpty ? "—" : ext
    }

    private var fileSizeString: String {
        guard let values = try? song.url.resourceValues(forKeys: [.fileSizeKey]),
              let bytes = values.fileSize, bytes > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private var dateAddedString: String {
        // `dateAdded` falls back to `.distantPast` when unavailable.
        guard song.dateAdded > .distantPast else { return "—" }
        return Self.dateFormatter.string(from: song.dateAdded)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
