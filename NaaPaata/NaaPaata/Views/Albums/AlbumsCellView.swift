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
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let artwork = album.artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: imageSize, height: imageSize)
                        .shadow(radius: 4)
                        .overlay(
                            Image(systemName: "opticaldisc")
                                .resizable()
                                .scaledToFit()
                                .frame(width: imageSize * 0.5, height: imageSize * 0.5)
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                
                Text("\(album.songs.count) song\(album.songs.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
