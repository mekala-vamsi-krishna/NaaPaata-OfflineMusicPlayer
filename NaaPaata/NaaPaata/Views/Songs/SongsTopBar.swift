//
//  SongsTopBar.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct SongsTopBar: View {
    @ObservedObject var viewModel: SongsViewModel
    var onSort: ((SongsViewModel.SortKey) -> Void)?

    var body: some View {
        HStack {
            Text("\(viewModel.totalSongs) Songs")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.leading, 5)

            Spacer()
            Spacer()

            HStack(spacing: 20) {
                Button(action: viewModel.playAll) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: viewModel.playShuffled) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Menu {
                    Button(action: { onSort?(.title) }) {
                        HStack {
                            Text("Title")
                            if viewModel.currentSort == .title {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    Button(action: { onSort?(.artist) }) {
                        HStack {
                            Text("Artist")
                            if viewModel.currentSort == .artist {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    Button(action: { onSort?(.duration) }) {
                        HStack {
                            Text("Duration")
                            if viewModel.currentSort == .duration {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    Button(action: { onSort?(.dateAddedDescending) }) {
                        HStack {
                            Text("Date Added (Newest)")
                            if viewModel.currentSort == .dateAddedDescending {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    Button(action: { onSort?(.dateAddedAscending) }) {
                        HStack {
                            Text("Date Added (Oldest)")
                            if viewModel.currentSort == .dateAddedAscending {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
