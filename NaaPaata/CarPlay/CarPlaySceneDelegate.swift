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

    private var playlistService: PlaylistService {
        PlaylistService(context: modelContext)
    }

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
        let songs     = makeSongsListTemplate()
        let albums    = makeAlbumsListTemplate()
        let playlists = makePlaylistsListTemplate()

        let tabBar = CPTabBarTemplate(templates: [songs, albums, playlists])
        tabBar.delegate = self
        return tabBar
    }

    // MARK: - Songs tab

    private func makeSongsListTemplate() -> CPListTemplate {
        songListItems.removeAll()
        currentlyHighlightedSongID = nil

        let allSongs = libraryViewModel.songs

        let songItems = allSongs.map { song in
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

        let tmpl = CPListTemplate(title: "Songs", sections: [CPListSection(items: songItems)])
        tmpl.tabImage = UIImage(systemName: "music.quarternote.3")
        return tmpl
    }

    // MARK: - Albums tab

    private func makeAlbumsListTemplate() -> CPListTemplate {
        let albums = libraryViewModel.albums

        let albumItems = albums.map { album in
            let item = CPListItem(
                text:       truncate(album.title, to: 23),
                detailText: "\(truncate(album.artist, to: 20)) • \(album.subtitle)",
                image:      artworkImage(for: album)
            )

            item.handler = { [weak self] _, done in
                self?.pushAlbumDetail(album: album)
                done()
            }
            return item
        }

        let section = CPListSection(
            items: albumItems.isEmpty
                ? [CPListItem(text: "No Albums", detailText: nil)]
                : albumItems
        )

        let tmpl = CPListTemplate(title: "Albums", sections: [section])
        tmpl.tabImage = UIImage(systemName: "rectangle.stack.badge.play")
        return tmpl
    }

    private func pushAlbumDetail(album: Album) {
        guard let interface = interfaceController else { return }
        let songs = album.songs

        let playAllItem = CPListItem(
            text: "Play All",
            detailText: "\(songs.count) songs",
            image: UIImage(systemName: "play.circle.fill")
        )
        playAllItem.handler = { [weak self] _, done in
            self?.libraryViewModel.playAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let shuffleItem = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffleItem.handler = { [weak self] _, done in
            self?.libraryViewModel.shuffleAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let songItems = songs.map { song in
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

        let headerSection = CPListSection(items: [playAllItem, shuffleItem])
        let songsSection = CPListSection(
            items: songItems,
            header: "\(songItems.count) \(songItems.count == 1 ? "Song" : "Songs")",
            sectionIndexTitle: ""
        )

        let detail = CPListTemplate(title: album.title, sections: [headerSection, songsSection])
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Playlists tab

    private func makePlaylistsListTemplate() -> CPListTemplate {
        let playlists = fetchPlaylists()

        let playlistItems = playlists.map { playlist in
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

        let section = CPListSection(
            items: playlistItems.isEmpty
                ? [CPListItem(text: "No Playlists", detailText: nil)]
                : playlistItems
        )

        let tmpl = CPListTemplate(title: "Playlists", sections: [section])
        tmpl.tabImage = UIImage(systemName: "music.note.list")
        return tmpl
    }

    private func pushPlaylistDetail(playlist: Playlist) {
        guard let interface = interfaceController else { return }

        let songs = resolvedSongs(for: playlist)

        let playAllItem = CPListItem(
            text: "Play All",
            detailText: "\(songs.count) songs",
            image: UIImage(systemName: "play.circle.fill")
        )
        playAllItem.handler = { [weak self] _, done in
            self?.libraryViewModel.playAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let shuffleItem = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffleItem.handler = { [weak self] _, done in
            self?.libraryViewModel.shuffleAll(songs)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let songItems = songs.map { song in
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

        let headerSection = CPListSection(items: [playAllItem, shuffleItem])
        let songsSection = CPListSection(
            items: songItems,
            header: "\(songItems.count) \(songItems.count == 1 ? "Song" : "Songs")",
            sectionIndexTitle: ""
        )

        let detail = CPListTemplate(title: playlist.name, sections: [headerSection, songsSection])
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Playlist helpers

    /// Fetches all playlists from SwiftData, newest first.
    private func fetchPlaylists() -> [Playlist] {
        let descriptor = FetchDescriptor<Playlist>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Resolves the playlist's stored relative paths against the
    /// in-memory library.
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
