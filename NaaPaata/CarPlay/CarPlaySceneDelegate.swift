//
//  CarPlaySceneDelegate.swift
//  NaaPaata
//

import Foundation
import CarPlay
import UIKit
import AVFoundation
import Combine
import MediaPlayer
import SwiftData

class CarPlaySceneDelegate: UIResponder,
                            CPTemplateApplicationSceneDelegate,
                            CPTabBarTemplateDelegate {

    // MARK: - Dependencies

    var interfaceController: CPInterfaceController?
    var libraryViewModel: MusicLibraryViewModel!
    var folderService: DocumentFolderService!
    var modelContext: ModelContext!

    private var cancellables = Set<AnyCancellable>()

    private lazy var placeholderArtwork = defaultArtworkImage()

    private var isNowPlayingActive   = false
    private var hasEnteredNowPlaying = false
    private var selectedTabIndex     = 0

    private var songListItems: [URL: CPListItem] = [:]
    private var currentlyHighlightedSongID: URL?

    private var nowPlayingTemplate: CPNowPlayingTemplate { .shared }

    /// Max images per `CPListImageRowItem`. CarPlay caps this visually;
    /// more than 8 pushes off-screen without adding value.
    private let imageRowLimit = 8

    // MARK: - Scene Lifecycle

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        guard
            let library = AppDelegate.libraryViewModel,
            let folder = AppDelegate.folderService,
            let container = AppDelegate.modelContainer
        else {
            fatalError("Services not initialized — NaaPaataApp must set them up before CarPlay connects")
        }

        self.libraryViewModel = library
        self.folderService = folder
        self.modelContext = container.mainContext

        observeLibraryViewModel()

        Task {
            await library.loadLibrary()

            let root = makeRootTabBarTemplate()
            root.delegate = self

            await MainActor.run {
                interfaceController.setRootTemplate(root, animated: true) { [weak self] _, _ in
                    guard let self else { return }
                    self.selectTab(at: self.selectedTabIndex, in: root)
                }
            }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        cancellables.removeAll()
        self.interfaceController = nil
        songListItems.removeAll()
        currentlyHighlightedSongID = nil
    }

    // MARK: - View model observation

    private func observeLibraryViewModel() {
        libraryViewModel.$currentSong
            .receive(on: RunLoop.main)
            .sink { [weak self] song in
                self?.handleCurrentSongChange(song)
            }
            .store(in: &cancellables)

        libraryViewModel.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handlePlaybackStateChange()
            }
            .store(in: &cancellables)

        libraryViewModel.$isShuffled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateNowPlayingButtons()
            }
            .store(in: &cancellables)

        libraryViewModel.$repeatMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateNowPlayingButtons()
            }
            .store(in: &cancellables)
    }

    private func handleCurrentSongChange(_ song: Song?) {
        updatePlayingIndicators(
            currentSong: song,
            isPlaying: libraryViewModel.isPlaying
        )

        if song != nil, !isNowPlayingActive, !hasEnteredNowPlaying {
            pushNowPlayingTemplate()
        }

        libraryViewModel.updateNowPlayingInfo()
        setPlaybackState(playing: libraryViewModel.isPlaying)
    }

    private func handlePlaybackStateChange() {
        updateNowPlayingButtons()
        updatePlayingIndicators(
            currentSong: libraryViewModel.currentSong,
            isPlaying: libraryViewModel.isPlaying
        )
        libraryViewModel.updateNowPlayingInfo()
        setPlaybackState(playing: libraryViewModel.isPlaying)
    }

    private func setPlaybackState(playing: Bool) {
        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        }
    }

    // MARK: - Tab bar delegate

    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        if let index = tabBarTemplate.templates.firstIndex(where: { $0 === selectedTemplate }) {
            selectedTabIndex = index
        }
    }

    // MARK: - Now playing indicator

    private func updatePlayingIndicators(currentSong: Song?, isPlaying: Bool) {
        let newID = isPlaying ? currentSong?.id : nil

        if currentlyHighlightedSongID == newID { return }

        if let prev = currentlyHighlightedSongID {
            songListItems[prev]?.isPlaying = false
        }
        if let next = newID {
            songListItems[next]?.isPlaying = true
        }

        currentlyHighlightedSongID = newID
    }

    // MARK: - Tab selection

    private func selectTab(at index: Int, in tabBar: CPTabBarTemplate) {
        guard index < tabBar.templates.count else { return }
        tabBar.selectTemplate(at: index)
    }

    // MARK: - Now Playing buttons

    private func updateNowPlayingButtons() {
        nowPlayingTemplate.updateNowPlayingButtons([
            makeShuffleButton(isActive: libraryViewModel.isShuffled),
            makeRepeatButton(mode: libraryViewModel.repeatMode)
        ])
    }

    private func pushNowPlayingTemplate() {
        guard let interface = interfaceController else { return }
        hasEnteredNowPlaying = true

        libraryViewModel.updateNowPlayingInfo()
        setPlaybackState(playing: libraryViewModel.isPlaying)

        interface.pushTemplate(nowPlayingTemplate, animated: true) { [weak self] success, _ in
            guard success, let self else { return }
            self.isNowPlayingActive = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.libraryViewModel.updateNowPlayingInfo()
                self.setPlaybackState(playing: self.libraryViewModel.isPlaying)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.libraryViewModel.updateNowPlayingInfo()
                self.setPlaybackState(playing: self.libraryViewModel.isPlaying)
            }
        }
    }

    private func makeShuffleButton(isActive: Bool) -> CPNowPlayingImageButton {
        let image = makeButtonImage(symbol: "shuffle", isActive: isActive)
        return CPNowPlayingImageButton(image: image) { [weak self] _ in
            self?.libraryViewModel.toggleShuffle()
            DispatchQueue.main.async {
                self?.updateNowPlayingButtons()
            }
        }
    }

    private func makeRepeatButton(mode: RepeatMode) -> CPNowPlayingImageButton {
        let symbol = mode == .one ? "repeat.1" : "repeat"
        let image = makeButtonImage(symbol: symbol, isActive: mode != .off)
        return CPNowPlayingImageButton(image: image) { [weak self] _ in
            self?.libraryViewModel.cycleRepeatMode()
            DispatchQueue.main.async {
                self?.updateNowPlayingButtons()
            }
        }
    }

    private func makeButtonImage(symbol: String, isActive: Bool) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        return UIImage(systemName: symbol, withConfiguration: configuration)?
            .withTintColor(
                isActive ? UIColor.tintColor : .white,
                renderingMode: .alwaysOriginal
            ) ?? UIImage()
    }

    // MARK: - Root tab bar

    private func makeRootTabBarTemplate() -> CPTabBarTemplate {
        let library   = makeLibraryTemplate()
        let playlists = makePlaylistsListTemplate()
        let search    = makeSearchPlaceholderTemplate()

        let tabBar = CPTabBarTemplate(templates: [library, playlists, search])
        tabBar.delegate = self
        return tabBar
    }

    // MARK: - Library tab (image-row grid)

    /// Library tab — shows horizontal rows of artwork for the top-level
    /// categories, mirroring Apple Music's CarPlay design.
    ///
    /// Each row uses `CPListImageRowItem` — the public CarPlay API for
    /// a horizontally scrolling strip of images with an optional title.
    private func makeLibraryTemplate() -> CPListTemplate {
        songListItems.removeAll()
        currentlyHighlightedSongID = nil

        var sections: [CPListSection] = []

        // ── Recently Added ──────────────────────────────────────────
        let recentlyAdded = Array(
            libraryViewModel.songs
                .sorted { $0.dateAdded > $1.dateAdded }
                .prefix(imageRowLimit)
        )
        if !recentlyAdded.isEmpty {
            let row = makeImageRow(
                title: "Recently Added",
                songs: recentlyAdded
            )
            sections.append(CPListSection(items: [row]))
        }

        // ── Albums ──────────────────────────────────────────────────
        let albums = Array(libraryViewModel.albums.prefix(imageRowLimit))
        if !albums.isEmpty {
            let row = makeImageRow(
                title: "Albums",
                albums: albums
            )
            sections.append(CPListSection(items: [row]))
        }

        // ── Artists ─────────────────────────────────────────────────
        let artists = Array(libraryViewModel.artists.prefix(imageRowLimit))
        if !artists.isEmpty {
            let row = makeImageRow(
                title: "Artists",
                artists: artists
            )
            sections.append(CPListSection(items: [row]))
        }

        // ── Playlists ───────────────────────────────────────────────
        let playlists = Array(fetchPlaylists().prefix(imageRowLimit))
        if !playlists.isEmpty {
            let row = makeImageRow(
                title: "Playlists",
                playlists: playlists
            )
            sections.append(CPListSection(items: [row]))
        }

        // ── All Songs ───────────────────────────────────────────────
        let allSongsRow = makeAllSongsRow()
        if !allSongsRow.items.isEmpty {
            sections.append(allSongsRow)
        }

        // Fallback: if truly nothing, show an empty state.
        if sections.isEmpty {
            let empty = CPListItem(
                text: "No Music Yet",
                detailText: "Add songs in the iPhone app"
            )
            sections = [CPListSection(items: [empty])]
        }

        let tmpl = CPListTemplate(title: "Library", sections: sections)
        tmpl.tabImage = UIImage(systemName: "square.grid.2x2.fill")
        return tmpl
    }

    // MARK: - Image row builders

    private func makeImageRow(title: String, songs: [Song]) -> CPListImageRowItem {
        let images = songs.map { artworkImage(for: $0) }
        let titles = songs.map { truncate($0.title, to: 20) }

        let row = CPListImageRowItem(
            text: title,
            images: images,
            imageTitles: titles
        )

        row.listImageRowHandler = { [weak self] _, index, done in
            guard let self, songs.indices.contains(index) else {
                done()
                return
            }
            self.libraryViewModel.play(songs[index], in: songs)
            self.pushNowPlayingIfNeeded()
            done()
        }

        return row
    }

    private func makeImageRow(title: String, albums: [Album]) -> CPListImageRowItem {
        let images = albums.map { artworkImage(for: $0) }
        let titles = albums.map { truncate($0.title, to: 20) }

        let row = CPListImageRowItem(
            text: title,
            images: images,
            imageTitles: titles
        )

        row.listImageRowHandler = { [weak self] _, index, done in
            guard let self, albums.indices.contains(index) else {
                done()
                return
            }
            self.pushAlbumDetail(album: albums[index])
            done()
        }

        return row
    }

    private func makeImageRow(title: String, artists: [Artist]) -> CPListImageRowItem {
        // Artist artwork is derived from their first song with artwork.
        let images = artists.map { artist -> UIImage in
            if let data = artist.artworkData, let image = UIImage(data: data) {
                return image
            }
            return placeholderArtwork
        }
        let titles = artists.map { truncate($0.name, to: 20) }

        let row = CPListImageRowItem(
            text: title,
            images: images,
            imageTitles: titles
        )

        row.listImageRowHandler = { [weak self] _, index, done in
            guard let self, artists.indices.contains(index) else {
                done()
                return
            }
            self.pushArtistDetail(artist: artists[index])
            done()
        }

        return row
    }

    private func makeImageRow(title: String, playlists: [Playlist]) -> CPListImageRowItem {
        let images = playlists.map { artworkImage(for: $0) }
        let titles = playlists.map { truncate($0.name, to: 20) }

        let row = CPListImageRowItem(
            text: title,
            images: images,
            imageTitles: titles
        )

        row.listImageRowHandler = { [weak self] _, index, done in
            guard let self, playlists.indices.contains(index) else {
                done()
                return
            }
            self.pushPlaylistDetail(playlist: playlists[index])
            done()
        }

        return row
    }

    /// A section containing the full songs list, so the user can still
    /// scroll the complete library from the Library tab.
    private func makeAllSongsRow() -> CPListSection {
        let allSongs = libraryViewModel.songs

        guard !allSongs.isEmpty else {
            return CPListSection(items: [])
        }

        let items = allSongs.prefix(50).map { song -> CPListItem in
            let item = CPListItem(
                text:       truncate(song.title, to: 23),
                detailText: "\(truncate(song.artist, to: 20)) • \(song.formattedDuration)",
                image:      artworkImage(for: song)
            )

            let playing = libraryViewModel.isPlaying && song.id == libraryViewModel.currentSong?.id
            item.isPlaying = playing
            if playing { currentlyHighlightedSongID = song.id }
            songListItems[song.id] = item

            item.handler = { [weak self] _, done in
                guard let self else { done(); return }
                self.libraryViewModel.play(song, in: allSongs)
                self.pushNowPlayingIfNeeded()
                done()
            }

            return item
        }

        return CPListSection(
            items: Array(items),
            header: "All Songs",
            sectionIndexTitle: nil
        )
    }

    // MARK: - Album detail

    private func pushAlbumDetail(album: Album) {
        guard let interface = interfaceController else { return }
        let songs = album.songs

        // ── Header section ──────────────────────────────────────────
        let hero = CPListItem(
            text: album.title,
            detailText: "\(album.artist) • \(album.songs.count) song\(album.songs.count == 1 ? "" : "s")",
            image: artworkImage(for: album)
        )
        hero.isEnabled = false

        let playAll = CPListItem(
            text: "Play",
            detailText: nil,
            image: UIImage(systemName: "play.fill")
        )
        playAll.handler = { [weak self] _, done in
            self?.libraryViewModel.playAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let shuffle = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffle.handler = { [weak self] _, done in
            self?.libraryViewModel.shuffleAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let headerSection = CPListSection(items: [hero, playAll, shuffle])

        // ── Songs section ───────────────────────────────────────────
        let songItems = songs.map { song -> CPListItem in
            let item = CPListItem(
                text:       truncate(song.title, to: 23),
                detailText: "\(truncate(song.artist, to: 20)) • \(song.formattedDuration)",
                image:      artworkImage(for: song)
            )
            item.isPlaying = libraryViewModel.isPlaying && song.id == libraryViewModel.currentSong?.id
            songListItems[song.id] = item

            item.handler = { [weak self] _, done in
                self?.libraryViewModel.play(song, in: songs)
                self?.pushNowPlayingIfNeeded()
                done()
            }
            return item
        }

        let songsSection = CPListSection(
            items: songItems,
            header: "\(songItems.count) \(songItems.count == 1 ? "Song" : "Songs")",
            sectionIndexTitle: nil
        )

        let detail = CPListTemplate(
            title: album.title,
            sections: [headerSection, songsSection]
        )
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Artist detail

    private func pushArtistDetail(artist: Artist) {
        guard let interface = interfaceController else { return }
        let songs = artist.songs

        let hero = CPListItem(
            text: artist.name,
            detailText: "\(songs.count) song\(songs.count == 1 ? "" : "s")",
            image: {
                if let data = artist.artworkData, let image = UIImage(data: data) {
                    return image
                }
                return placeholderArtwork
            }()
        )
        hero.isEnabled = false

        let playAll = CPListItem(
            text: "Play",
            detailText: nil,
            image: UIImage(systemName: "play.fill")
        )
        playAll.handler = { [weak self] _, done in
            self?.libraryViewModel.playAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let shuffle = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffle.handler = { [weak self] _, done in
            self?.libraryViewModel.shuffleAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let headerSection = CPListSection(items: [hero, playAll, shuffle])

        let songItems = songs.map { song -> CPListItem in
            let item = CPListItem(
                text:       truncate(song.title, to: 23),
                detailText: "\(truncate(song.album, to: 20)) • \(song.formattedDuration)",
                image:      artworkImage(for: song)
            )
            item.isPlaying = libraryViewModel.isPlaying && song.id == libraryViewModel.currentSong?.id
            songListItems[song.id] = item

            item.handler = { [weak self] _, done in
                self?.libraryViewModel.play(song, in: songs)
                self?.pushNowPlayingIfNeeded()
                done()
            }
            return item
        }

        let songsSection = CPListSection(
            items: songItems,
            header: "\(songItems.count) \(songItems.count == 1 ? "Song" : "Songs")",
            sectionIndexTitle: nil
        )

        let detail = CPListTemplate(
            title: artist.name,
            sections: [headerSection, songsSection]
        )
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Playlists tab

    private func makePlaylistsListTemplate() -> CPListTemplate {
        let playlists = fetchPlaylists()

        guard !playlists.isEmpty else {
            let empty = CPListItem(
                text: "No Playlists",
                detailText: "Create one in the iPhone app"
            )
            let tmpl = CPListTemplate(title: "Playlists", sections: [CPListSection(items: [empty])])
            tmpl.tabImage = UIImage(systemName: "music.note.list")
            return tmpl
        }

        // Row of playlist covers at the top
        let gridRow = makeImageRow(
            title: "Recently Created",
            playlists: Array(playlists.prefix(imageRowLimit))
        )

        // Full list below
        let listItems = playlists.map { playlist -> CPListItem in
            let count = playlist.songRelativePaths.count
            let item = CPListItem(
                text:       truncate(playlist.name, to: 23),
                detailText: "\(count) song\(count == 1 ? "" : "s")",
                image:      artworkImage(for: playlist)
            )
            item.handler = { [weak self] _, done in
                self?.pushPlaylistDetail(playlist: playlist)
                done()
            }
            return item
        }

        let tmpl = CPListTemplate(
            title: "Playlists",
            sections: [
                CPListSection(items: [gridRow]),
                CPListSection(items: listItems, header: "All Playlists", sectionIndexTitle: nil)
            ]
        )
        tmpl.tabImage = UIImage(systemName: "music.note.list")
        return tmpl
    }

    private func pushPlaylistDetail(playlist: Playlist) {
        guard let interface = interfaceController else { return }

        let songs = resolvedSongs(for: playlist)

        let hero = CPListItem(
            text: playlist.name,
            detailText: "\(songs.count) song\(songs.count == 1 ? "" : "s")",
            image: artworkImage(for: playlist)
        )
        hero.isEnabled = false

        let playAll = CPListItem(
            text: "Play",
            detailText: nil,
            image: UIImage(systemName: "play.fill")
        )
        playAll.handler = { [weak self] _, done in
            self?.libraryViewModel.playAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let shuffle = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffle.handler = { [weak self] _, done in
            self?.libraryViewModel.shuffleAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let headerSection = CPListSection(items: [hero, playAll, shuffle])

        let songItems = songs.map { song -> CPListItem in
            let item = CPListItem(
                text:       truncate(song.title, to: 23),
                detailText: "\(truncate(song.artist, to: 20)) • \(song.formattedDuration)",
                image:      artworkImage(for: song)
            )
            item.isPlaying = libraryViewModel.isPlaying && song.id == libraryViewModel.currentSong?.id
            songListItems[song.id] = item

            item.handler = { [weak self] _, done in
                self?.libraryViewModel.play(song, in: songs)
                self?.pushNowPlayingIfNeeded()
                done()
            }
            return item
        }

        let songsSection = CPListSection(
            items: songItems,
            header: "\(songItems.count) \(songItems.count == 1 ? "Song" : "Songs")",
            sectionIndexTitle: nil
        )

        let detail = CPListTemplate(
            title: playlist.name,
            sections: [headerSection, songsSection]
        )
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Search placeholder

    private func makeSearchPlaceholderTemplate() -> CPListTemplate {
        let item = CPListItem(
            text: "Use Siri to search",
            detailText: "Say \"Play [song name] on Naa Paata\"",
            image: UIImage(systemName: "mic.fill")
        )

        let tmpl = CPListTemplate(title: "Search", sections: [CPListSection(items: [item])])
        tmpl.tabImage = UIImage(systemName: "magnifyingglass")
        return tmpl
    }

    // MARK: - Playlist helpers

    private func fetchPlaylists() -> [Playlist] {
        let descriptor = FetchDescriptor<Playlist>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func resolvedSongs(for playlist: Playlist) -> [Song] {
        libraryViewModel.songs(
            forRelativePaths: playlist.songRelativePaths,
            folderService: folderService
        )
    }

    // MARK: - Push helpers

    private func pushNowPlayingIfNeeded() {
        guard !hasEnteredNowPlaying else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.pushNowPlayingTemplate()
        }
    }

    // MARK: - Artwork

    private func artworkImage(for song: Song) -> UIImage {
        if let data = song.artworkData, let image = UIImage(data: data) {
            return image
        }
        return placeholderArtwork
    }

    private func artworkImage(for album: Album) -> UIImage {
        if let data = album.artworkData, let image = UIImage(data: data) {
            return image
        }
        return placeholderArtwork
    }

    private func artworkImage(for playlist: Playlist) -> UIImage {
        if let data = playlist.coverImageData, let image = UIImage(data: data) {
            return image
        }
        return placeholderArtwork
    }

    private func truncate(_ text: String, to max: Int) -> String {
        guard text.count > max else { return text }
        return String(text.prefix(max - 1)) + "…"
    }

    private func defaultArtworkImage() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8).fill()

            let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            if let note = UIImage(systemName: "music.note", withConfiguration: cfg)?
                .withTintColor(UIColor.tintColor, renderingMode: .alwaysOriginal) {
                note.draw(at: CGPoint(
                    x: (size.width  - note.size.width)  / 2,
                    y: (size.height - note.size.height) / 2
                ))
            }
        }
    }
}
