//
//  SmartPlaylistRowView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct SmartPlaylistRowView: View {

    let kind: SmartPlaylistKind
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            artwork

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title)
                    .font(.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text("\(count) song\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer(minLength: 16)

            Text("Smart Playlist")
                .font(.caption)
                .foregroundStyle(AppColor.textTertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var artwork: some View {
        ZStack {
            kind.gradient

            Image(systemName: kind.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
