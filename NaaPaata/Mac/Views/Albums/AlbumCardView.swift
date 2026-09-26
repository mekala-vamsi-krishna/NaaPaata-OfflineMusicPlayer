//
//  AlbumCardView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI

struct AlbumCardView: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(data: album.artworkData, size: 170, cornerRadius: 10)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text("\(album.trackCount) song\(album.trackCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .help("\(album.title) — \(album.artist)")
    }
}
