//
//  SmartPlaylistCardView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/9/26.
//

import SwiftUI
import UIKit

struct SmartPlaylistCardView: View {

    let playlist: SmartPlaylist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            artwork
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(playlist.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            playlist.gradient

            Image(systemName: playlist.symbol)
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(.white.opacity(0.32))
        }
    }
}
