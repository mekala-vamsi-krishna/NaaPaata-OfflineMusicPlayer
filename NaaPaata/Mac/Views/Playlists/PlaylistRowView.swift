//
//  PlaylistRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI
import AppKit

struct PlaylistRowView: View {

    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(playlist.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Text(playlist.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var artwork: some View {
        ZStack {
            if let data = playlist.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient

                    Image(systemName: "music.note.list")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
