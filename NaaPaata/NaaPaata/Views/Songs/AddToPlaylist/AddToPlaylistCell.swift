//
//  AddToPlaylistCell.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/26/26.
//

import SwiftUI

struct AddToPlaylistCell: View {
    let playlist: Playlist
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            // Cover
            if let cover = playlist.coverImage {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.title3)
                            .foregroundColor(AppColors.primary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(playlist.songPaths.count) songs")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.leading, 4)

            Spacer()

            // Selection button
            Button {
                isSelected.toggle()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .stroke(AppColors.primary, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
    }
}
