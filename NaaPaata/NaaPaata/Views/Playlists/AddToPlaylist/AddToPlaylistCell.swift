//
//  AddToPlaylistCell.swift
//  NaaPaata
//

import SwiftUI
import UIKit

struct AddToPlaylistCell: View {

    let playlist: Playlist
    @Binding var isSelected: Bool

    private var coverImage: UIImage? {
        guard let data = playlist.coverImageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        HStack(spacing: 12) {

            cover

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(songCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            selectionButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Cover

    @ViewBuilder
    private var cover: some View {
        if let coverImage {
            Image(uiImage: coverImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))

                Image(systemName: "music.note.list")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 44, height: 44)
        }
    }

    // MARK: - Count label

    private var songCountLabel: String {
        let count = playlist.songRelativePaths.count
        return "\(count) song\(count == 1 ? "" : "s")"
    }

    // MARK: - Selection button

    private var selectionButton: some View {
        Button {
            isSelected.toggle()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 28, height: 28)

                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
