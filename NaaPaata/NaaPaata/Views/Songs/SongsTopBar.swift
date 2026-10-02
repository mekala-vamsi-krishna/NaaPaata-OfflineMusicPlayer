//
//  SongsTopBar.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct SongsTopBar: View {

    let count: Int
    @Binding var sortOption: SongSortOption
    let onPlayAll: () -> Void
    let onShuffleAll: () -> Void

    var body: some View {
        HStack {
            Text("\(count) Song\(count == 1 ? "" : "s")")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 8) {

                Button(action: onPlayAll) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play All")

                Button(action: onShuffleAll) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Shuffle All")

                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SongSortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Sort")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
