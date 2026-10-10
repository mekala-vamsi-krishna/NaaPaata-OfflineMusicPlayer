//
//  PlaylistCardView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI
import AppKit

struct PlaylistCardView: View {

    let playlist: Playlist

    /// Single source of truth for the card's width — used by artwork and text.
    static let cardWidth: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(playlist.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: Self.cardWidth, alignment: .leading)
        }
        .frame(width: Self.cardWidth, alignment: .leading)
    }

    private var artwork: some View {
        ZStack {
            if let data = playlist.artworkData,
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: Self.cardWidth, height: Self.cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColor.border)
        )
    }

    private var placeholder: some View {
        ZStack {
            AppColor.brandGradient

            Image(systemName: "music.note.list")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
