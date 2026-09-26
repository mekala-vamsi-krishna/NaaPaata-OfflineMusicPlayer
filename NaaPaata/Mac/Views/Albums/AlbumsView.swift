// Views/Albums/AlbumsView.swift
import SwiftUI

struct AlbumsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    
    @State private var sortOption: AlbumSortOption = .titleAscending
    @AppStorage("albums.sortOption") private var storedSortRawValue = AlbumSortOption.titleAscending.rawValue

    private let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 22, alignment: .leading)
    ]

    private var displayedAlbums: [Album] {
        viewModel.albums.sorted(by: sortOption.areInIncreasingOrder)
    }

    var body: some View {
        Group {
            if viewModel.albums.isEmpty {
                EmptyStateView(
                    title: "No Albums Yet",
                    systemImage: "square.stack",
                    message: "Albums are created automatically from your songs' album metadata.",
                    actionTitle: "Open Library Folder",
                    action: viewModel.revealLibraryInFinder
                )
            } else {
                albumGrid
            }
        }
        .navigationTitle("Albums")
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album, viewModel: viewModel)
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onAppear {
            sortOption = AlbumSortOption(rawValue: storedSortRawValue) ?? .titleAscending
        }
        .onChange(of: sortOption) { _, newValue in
            storedSortRawValue = newValue.rawValue
        }
    }

    // MARK: - Grid + header
    
    private var albumGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(displayedAlbums) { album in
                    NavigationLink(value: album) {
                        AlbumCardView(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            headerBar
        }
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 10) {

            Spacer()

            sortMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 1)
        }
    }

    // MARK: - Sort menu

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                ForEach(AlbumSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sort albums")
    }
}
