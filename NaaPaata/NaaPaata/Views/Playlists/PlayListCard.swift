//
//  PlayListCard.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/25.
//

import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist
    let cardHeight: CGFloat
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                // Glow effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(RadialGradient(colors: [AppColors.primary.opacity(0.3), .clear],
                                         center: .center, startRadius: 60, endRadius: 90))
                    .frame(height: cardHeight)
                    .blur(radius: 20)
                
                // Main card
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: cardHeight)
                    .overlay(
                        GeometryReader { geometry in
                            ZStack {
                                // Cover image – fills the whole card exactly
                                if let image = playlist.coverImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                } else {
                                    Image("default_playlist_cover")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                }
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(colors: [.white.opacity(0.2), .clear],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(playlist.songPaths.isEmpty ? "Empty" : "\(playlist.songPaths.count) song\(playlist.songPaths.count == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppColors.textSecondary)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}
