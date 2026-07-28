//
//  AlbumsTopBar.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct AlbumsTopBar: View {
    @ObservedObject var viewModel: AlbumsViewModel
    var count: Int
    var onSort: ((AlbumsViewModel.SortKey) -> Void)?

    var body: some View {
        HStack {
            Text("\(count) Album\(count == 1 ? "" : "s")")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 16) {
                Menu {
                    Button(action: { onSort?(.name) }) {
                        HStack {
                            Text("Name")
                            if viewModel.currentSort == .name {
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
                    Button(action: { onSort?(.dateModified) }) {
                        HStack {
                            Text("Date Modified")
                            if viewModel.currentSort == .dateModified {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    Button(action: { onSort?(.size) }) {
                        HStack {
                            Text("Size")
                            if viewModel.currentSort == .size {
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
        .padding(.vertical, 8)
    }
}
