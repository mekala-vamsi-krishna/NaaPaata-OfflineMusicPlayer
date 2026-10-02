//
//  SongInfoView.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct SongInfoView: View {

    let song: Song

    // MARK: - Derived values

    private var durationString: String {
        song.formattedDuration
    }

    private var fileFormat: String {
        let ext = song.url.pathExtension.uppercased()
        return ext.isEmpty ? "—" : ext
    }

    private var mimeType: String {
        switch song.url.pathExtension.lowercased() {
        case "mp3":           return "audio/mpeg"
        case "m4a", "aac":    return "audio/mp4"
        case "wav":           return "audio/wav"
        case "aif", "aiff":   return "audio/aiff"
        case "caf":           return "audio/x-caf"
        case "flac":          return "audio/flac"
        case "alac":          return "audio/alac"
        case "ogg", "oga":    return "audio/ogg"
        case "opus":          return "audio/opus"
        default:              return "—"
        }
    }

    private var fileSizeString: String {
        guard let values = try? song.url.resourceValues(forKeys: [.fileSizeKey]),
              let bytes = values.fileSize, bytes > 0
        else { return "—" }

        return ByteCountFormatter.string(
            fromByteCount: Int64(bytes),
            countStyle: .file
        )
    }

    private var dateAddedString: String {
        Self.dateFormatter.string(from: song.dateAdded)
    }

    private var artworkImage: UIImage? {
        guard let data = song.artworkData else { return nil }
        return UIImage(data: data)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                artworkView

                metadataCard

                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Song Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        if let artworkImage {
            Image(uiImage: artworkImage)
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                .padding(.top, 20)
                .padding(.horizontal)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.gray.opacity(0.15))

                Image(systemName: "music.note")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }
            .frame(height: 220)
            .padding(.top, 20)
            .padding(.horizontal)
        }
    }

    // MARK: - Metadata card

    private var metadataCard: some View {
        VStack(spacing: 12) {
            metadataRow(label: "Title",  value: song.title)
            metadataRow(label: "Artist", value: song.artist)
            metadataRow(label: "Album",  value: song.album)
            metadataRow(label: "Genre",  value: song.genre)
            metadataRow(label: "Duration", value: durationString)
            metadataRow(label: "Format", value: fileFormat)
            metadataRow(label: "MIME Type", value: mimeType)
            metadataRow(label: "File Size", value: fileSizeString)
            metadataRow(label: "Date Added", value: dateAddedString)

            Divider()
                .padding(.vertical, 4)

            pathRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Row builders

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }

    private var pathRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Location")
                .fontWeight(.semibold)

            Text(song.url.path)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
