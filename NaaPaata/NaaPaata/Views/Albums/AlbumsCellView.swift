//
//  AlbumsCellView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct AlbumCellView: View {
    let album: Album
    let imageSize: CGFloat
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if let artwork = album.artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                } else {
                    Image("default_playlist_cover")
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 6)
                
                Text("\(album.songs.count) song\(album.songs.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
            }
        }
    }
}
