//
//  CarPlayTemplateFactory.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/20/26.
//

import CarPlay
import UIKit

@MainActor
final class CarPlayTemplateFactory {
    
    // Action callbacks (injected by the Delegate)
    var onPlaySong: ((Song, [Song]) -> Void)?
    var onPlayAll: (([Song]) -> Void)?
    var onShuffleAll: (([Song]) -> Void)?
    var onPushTemplate: ((CPTemplate) -> Void)?
    var onShowNowPlaying: (() -> Void)?
    var onShowRecents: (() -> Void)?
    
    private let themeColor: UIColor
    private let placeholderArtwork: UIImage
    
    // Keep track of list items to update the playing indicator
    private(set) var songListItems: [URL: CPListItem] = [:]
    
    init(themeColor: UIColor, placeholderArtwork: UIImage) {
        self.themeColor = themeColor
        self.placeholderArtwork = placeholderArtwork
    }
    
    func clearItems() {
        songListItems.removeAll()
    }
    
    func updatePlayingIndicator(currentSong: Song?, isPlaying: Bool) {
        let activeID = isPlaying ? currentSong?.id : nil
        
        for (id, item) in songListItems {
            item.isPlaying = (id == activeID)
        }
    }

    // MARK: - Root Tabs
    
    func makeRootTabBarTemplate(dataProvider: CarPlayDataProvider) -> CPTabBarTemplate {
        let library = makeLibraryTemplate(dataProvider: dataProvider)
        let playlists = makePlaylistsListTemplate(dataProvider: dataProvider)
        let search = makeSearchPlaceholderTemplate()
        
        return CPTabBarTemplate(templates: [library, playlists, search])
    }

    // MARK: - Library Tab
    
    private func makeLibraryTemplate(dataProvider: CarPlayDataProvider) -> CPListTemplate {
        clearItems()
        var sections: [CPListSection] = []
        
        let recents = Array(dataProvider.songs.sorted { $0.dateAdded > $1.dateAdded }.prefix(30))
        if !recents.isEmpty {
            sections.append(CPListSection(items: [makeRecentsRow(songs: recents)]))
        }

        let browseItems: [CPListItem] = [
            makeBrowseItem(title: "Songs", detail: "\(dataProvider.songs.count) songs", symbol: "music.note") { [weak self] in self?.pushSongsList(dataProvider) },
            makeBrowseItem(title: "Albums", detail: "\(dataProvider.albums.count) albums", symbol: "square.stack") { [weak self] in self?.pushAlbumsList(dataProvider) },
            makeBrowseItem(title: "Artists", detail: "\(dataProvider.artists.count) artists", symbol: "music.mic") { [weak self] in self?.pushArtistsList(dataProvider) },
            makeBrowseItem(title: "Genres", detail: "\(dataProvider.genres.count) genres", symbol: "guitars") { [weak self] in self?.pushGenresList(dataProvider) },
            makeBrowseItem(title: "Favorites", detail: dataProvider.favouritesCountText(), symbol: "heart.fill") { [weak self] in self?.pushFavouritesList(dataProvider) },
        ]
        sections.append(CPListSection(items: browseItems))

        let tmpl = CPListTemplate(title: "Library", sections: sections)
        tmpl.tabImage = UIImage(systemName: "square.grid.2x2.fill")
        return tmpl
    }

    private func makeRecentsRow(songs: [Song]) -> CPListImageRowItem {
        let images = songs.map { artworkImage(for: $0) }
        let titles = songs.map { truncate($0.title, to: 20) }
        let row = CPListImageRowItem(text: "Recents", images: images, imageTitles: titles)

        row.listImageRowHandler = { [weak self] _, index, done in
            guard let self, songs.indices.contains(index) else { done(); return }
            self.onPlaySong?(songs[index], songs)
            self.onShowNowPlaying?()
            done()
        }
        
        row.handler = { [weak self] _, done in
            self?.onShowRecents?()
            done()
        }
        return row
    }

    private func makeBrowseItem(title: String, detail: String, symbol: String, action: @escaping () -> Void) -> CPListItem {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: symbol, withConfiguration: config)?.withTintColor(themeColor, renderingMode: .alwaysOriginal)
        let item = CPListItem(text: title, detailText: detail, image: image)
        item.accessoryType = .disclosureIndicator
        item.handler = { _, done in action(); done() }
        return item
    }

    // MARK: - Detail Lists
    
    private func pushSongsList(_ dataProvider: CarPlayDataProvider) {
        let sections = buildDetailSections(for: dataProvider.songs)
        let tmpl = CPListTemplate(title: "Songs", sections: sections)
        onPushTemplate?(tmpl)
    }

    private func pushFavouritesList(_ dataProvider: CarPlayDataProvider) {
        let songs = dataProvider.resolveFavourites()
        guard !songs.isEmpty else {
            let empty = CPListItem(text: "No Favourites Yet", detailText: "Tap the star on any song in the iPhone app")
            onPushTemplate?(CPListTemplate(title: "Favorites", sections: [CPListSection(items: [empty])]))
            return
        }
        let sections = buildDetailSections(for: songs)
        onPushTemplate?(CPListTemplate(title: "Favorites", sections: sections))
    }

    private func pushAlbumsList(_ dataProvider: CarPlayDataProvider) {
        let items = dataProvider.albums.map { album -> CPListItem in
            let item = CPListItem(text: truncate(album.title, to: 23), detailText: "\(truncate(album.artist, to: 20)) • \(album.songs.count) songs", image: artworkImage(for: album))
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, done in
                self?.pushAlbumDetail(album: album)
                done()
            }
            return item
        }
        onPushTemplate?(CPListTemplate(title: "Albums", sections: [CPListSection(items: items)]))
    }

    private func pushArtistsList(_ dataProvider: CarPlayDataProvider) {
        let items = dataProvider.artists.map { artist -> CPListItem in
            let image = artist.artworkData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
            let item = CPListItem(text: truncate(artist.name, to: 23), detailText: "\(artist.songCount) songs", image: image)
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, done in self?.pushArtistDetail(artist: artist); done() }
            return item
        }
        onPushTemplate?(CPListTemplate(title: "Artists", sections: [CPListSection(items: items)]))
    }

    private func pushGenresList(_ dataProvider: CarPlayDataProvider) {
        let items = dataProvider.genres.map { genre -> CPListItem in
            let image = genre.artworkData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
            let item = CPListItem(text: truncate(genre.name, to: 23), detailText: "\(genre.songCount) songs", image: image)
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, done in self?.pushGenreDetail(genre: genre); done() }
            return item
        }
        onPushTemplate?(CPListTemplate(title: "Genres", sections: [CPListSection(items: items)]))
    }

    // MARK: - Album/Artist/Genre Details
    
    private func pushAlbumDetail(album: Album) {
        let sections = buildDetailSections(for: album.songs, headerTitle: album.title, headerImage: artworkImage(for: album), headerSubtitle: album.artist)
        onPushTemplate?(CPListTemplate(title: album.title, sections: sections))
    }

    private func pushArtistDetail(artist: Artist) {
        let heroImage = artist.artworkData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
        let sections = buildDetailSections(for: artist.songs, headerTitle: artist.name, headerImage: heroImage, headerSubtitle: "\(artist.songCount) songs")
        onPushTemplate?(CPListTemplate(title: artist.name, sections: sections))
    }

    private func pushGenreDetail(genre: Genre) {
        let heroImage = genre.artworkData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
        let sections = buildDetailSections(for: genre.songs, headerTitle: genre.name, headerImage: heroImage, headerSubtitle: "\(genre.songCount) songs")
        onPushTemplate?(CPListTemplate(title: genre.name, sections: sections))
    }
    
    func pushPlaylistDetail(playlist: Playlist, dataProvider: CarPlayDataProvider) {
        let songs = dataProvider.resolvedSongs(for: playlist)
        let sections = buildDetailSections(for: songs, headerTitle: playlist.name, headerImage: artworkImage(for: playlist), headerSubtitle: "\(songs.count) songs")
        onPushTemplate?(CPListTemplate(title: playlist.name, sections: sections))
    }
    
    func pushRecentsList(dataProvider: CarPlayDataProvider) {
        let recents = dataProvider.songs.sorted { $0.dateAdded > $1.dateAdded }
        guard !recents.isEmpty else {
            let empty = CPListItem(text: "No Recent Songs", detailText: "Add songs to your library to see them here")
            onPushTemplate?(CPListTemplate(title: "Recents", sections: [CPListSection(items: [empty])]))
            return
        }
        let heroImage = recents.first.flatMap { artworkImage(for: $0) } ?? placeholderArtwork
        let sections = buildDetailSections(for: recents, headerTitle: "Recents", headerImage: heroImage, headerSubtitle: "\(recents.count) songs")
        onPushTemplate?(CPListTemplate(title: "Recents", sections: sections))
    }

    // MARK: - Shared Builders

    private func buildDetailSections(for songs: [Song], headerTitle: String? = nil, headerImage: UIImage? = nil, headerSubtitle: String? = nil) -> [CPListSection] {
        var sections: [CPListSection] = []
        let safeImage = headerImage ?? placeholderArtwork

        if let title = headerTitle, let subtitle = headerSubtitle {
            let hero = CPListItem(text: title, detailText: subtitle, image: safeImage)
            hero.isEnabled = false
            sections.append(CPListSection(items: [hero]))

            if !songs.isEmpty {
                let playItem = makeActionItem(title: "Play", symbol: "play.fill") { [weak self] in
                    self?.onPlayAll?(songs)
                    self?.onShowNowPlaying?()
                }
                let shuffleItem = makeActionItem(title: "Shuffle", symbol: "shuffle") { [weak self] in
                    self?.onShuffleAll?(songs)
                    self?.onShowNowPlaying?()
                }
                sections.append(CPListSection(items: [playItem, shuffleItem]))
            }
        } else if !songs.isEmpty {
            let playItem = makeActionItem(title: "Play", symbol: "play.fill") { [weak self] in
                self?.onPlayAll?(songs)
                self?.onShowNowPlaying?()
            }
            let shuffleItem = makeActionItem(title: "Shuffle", symbol: "shuffle") { [weak self] in
                self?.onShuffleAll?(songs)
                self?.onShowNowPlaying?()
            }
            sections.append(CPListSection(items: [playItem, shuffleItem]))
        }

        let songItems = songs.enumerated().map { index, song -> CPListItem in
            let title = "\(index + 1). \(song.title)"
            let item = CPListItem(text: truncate(title, to: 25), detailText: "\(truncate(song.artist, to: 20)) • \(song.formattedDuration)", image: artworkImage(for: song))
            songListItems[song.id] = item
            item.handler = { [weak self] _, done in
                self?.onPlaySong?(song, songs)
                self?.onShowNowPlaying?()
                done()
            }
            return item
        }
        
        let sectionHeader = songs.isEmpty ? nil : "\(songItems.count) \(songItems.count == 1 ? "Song" : "Songs")"
        sections.append(CPListSection(items: songItems, header: sectionHeader, sectionIndexTitle: nil))
        return sections
    }

    private func makeActionItem(title: String, symbol: String, action: @escaping () -> Void) -> CPListItem {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: symbol, withConfiguration: config)?.withTintColor(themeColor, renderingMode: .alwaysOriginal)
        let item = CPListItem(text: title, detailText: nil, image: image)
        item.handler = { _, done in action(); done() }
        return item
    }

    // MARK: - Playlists & Search

    private func makePlaylistsListTemplate(dataProvider: CarPlayDataProvider) -> CPListTemplate {
        let playlists = dataProvider.fetchPlaylists()
        guard !playlists.isEmpty else {
            let empty = CPListItem(text: "No Playlists", detailText: "Create one in the iPhone app")
            let tmpl = CPListTemplate(title: "Playlists", sections: [CPListSection(items: [empty])])
            tmpl.tabImage = UIImage(systemName: "music.note.list")
            return tmpl
        }
        let listItems = playlists.map { playlist -> CPListItem in
            let count = playlist.songRelativePaths.count
            let item = CPListItem(text: truncate(playlist.name, to: 23), detailText: "\(count) song\(count == 1 ? "" : "s")", image: artworkImage(for: playlist))
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, done in
                self?.pushPlaylistDetail(playlist: playlist, dataProvider: dataProvider)
                done()
            }
            return item
        }
        let tmpl = CPListTemplate(title: "Playlists", sections: [CPListSection(items: listItems)])
        tmpl.tabImage = UIImage(systemName: "music.note.list")
        return tmpl
    }

    private func makeSearchPlaceholderTemplate() -> CPListTemplate {
        let item = CPListItem(text: "Use Siri to search", detailText: "Say \"Play [song name] on Naa Paata\"", image: UIImage(systemName: "mic.fill"))
        let tmpl = CPListTemplate(title: "Search", sections: [CPListSection(items: [item])])
        tmpl.tabImage = UIImage(systemName: "magnifyingglass")
        return tmpl
    }

    // MARK: - Helpers

    private func artworkImage(for song: Song) -> UIImage {
        return song.artworkData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
    }
    private func artworkImage(for album: Album) -> UIImage {
        return album.artworkData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
    }
    private func artworkImage(for playlist: Playlist) -> UIImage {
        return playlist.coverImageData.flatMap { UIImage(data: $0) } ?? placeholderArtwork
    }

    private func truncate(_ text: String, to max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max - 1)) + "…"
    }
}
