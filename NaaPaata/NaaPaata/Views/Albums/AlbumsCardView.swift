//
//  AlbumsCardView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import SwiftUI

struct AlbumCardView: View {

    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(data: album.artworkData, size: 160, cornerRadius: 10)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(album.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
