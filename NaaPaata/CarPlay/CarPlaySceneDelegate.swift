//
//  CarPlaySceneDelegate.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/5/26.
//

import Foundation
import CarPlay
import UIKit
import AVFoundation
import SwiftData
import MediaPlayer

class CarPlaySceneDelegate: UIResponder,
                            CPTemplateApplicationSceneDelegate,
                            MusicPlayerManagerDelegate,
                            CPTabBarTemplateDelegate {

    // MARK: - Properties
    var interfaceController: CPInterfaceController?
    private lazy var placeholderArtwork = defaultArtworkImage()

    let songsViewModel    = SongsViewModel()
    let albumsViewModel   = AlbumsViewModel()
    let playlistsViewModel = PlaylistsViewModel()

    private var isNowPlayingActive   = false
    private var hasEnteredNowPlaying = false
    private var selectedTabIndex     = 0

    private var songListItems: [UUID: CPListItem] = [:]
    private var currentlyHighlightedSongID: UUID?

    private var nowPlayingTemplate: CPNowPlayingTemplate { .shared }

    // MARK: - Scene Lifecycle

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        MusicPlayerManager.shared.delegate = self

        let context = PersistenceController.shared.container.mainContext
        songsViewModel.setup(modelContext: context)

        Task {
            await songsViewModel.loadSongs()
            albumsViewModel.fetchAlbums(from: songsViewModel.songs)

            let root = makeRootTabBarTemplate()
            root.delegate = self
            await MainActor.run {
                interfaceController.setRootTemplate(root, animated: true) { [weak self] _, _ in
                    self?.selectTab(at: self?.selectedTabIndex ?? 0, in: root)
                }
            }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        MusicPlayerManager.shared.delegate = nil
        self.interfaceController = nil
        songListItems.removeAll()
        currentlyHighlightedSongID = nil
    }

    // MARK: - MusicPlayerManagerDelegate

    func musicPlayerManager(_ manager: MusicPlayerManager, didChangeCurrentSong song: Song?) {
        updatePlayingIndicators(currentSong: song, isPlaying: manager.isPlaying)
        if song != nil && !isNowPlayingActive && !hasEnteredNowPlaying {
            pushNowPlayingTemplate()
        }
        manager.updateNowPlayingInfo()
        setPlaybackState(playing: manager.isPlaying)
    }

    func musicPlayerManagerDidChangePlaybackState(_ manager: MusicPlayerManager) {
        updateNowPlayingButtons()
        updatePlayingIndicators(currentSong: manager.currentSong, isPlaying: manager.isPlaying)
        manager.updateNowPlayingInfo()
        setPlaybackState(playing: manager.isPlaying)
    }

    func musicPlayerManagerDidChangeShuffle(_ manager: MusicPlayerManager) {
        updateNowPlayingButtons()
    }

    func musicPlayerManagerDidChangeRepeat(_ manager: MusicPlayerManager) {
        updateNowPlayingButtons()
    }

    // MARK: - Helper to set playback state in NowPlayingInfoCenter

    private func setPlaybackState(playing: Bool) {
        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        }
    }

    // MARK: - CPTabBarTemplateDelegate

    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        if let index = tabBarTemplate.templates.firstIndex(where: { $0 === selectedTemplate }) {
            selectedTabIndex = index
        }
    }

    // MARK: - Now playing indicator update

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

    // MARK: - Shared UI helpers

    private func selectTab(at index: Int, in tabBar: CPTabBarTemplate) {
        guard index < tabBar.templates.count else { return }
        tabBar.selectTemplate(at: index)
    }

    private func updateNowPlayingButtons() {
        let m = MusicPlayerManager.shared
        nowPlayingTemplate.updateNowPlayingButtons([
            makeShuffleButton(isActive: m.shuffleIsActive),
            makeRepeatButton(mode: m.currentRepeatMode),
        ])
    }

    // MARK: - Now Playing navigation

    private func pushNowPlayingTemplate() {
        guard let interface = interfaceController else { return }
        hasEnteredNowPlaying = true

        let manager = MusicPlayerManager.shared
        manager.updateNowPlayingInfo()
        setPlaybackState(playing: manager.isPlaying)

        interface.pushTemplate(nowPlayingTemplate, animated: true) { [weak self] success, _ in
            guard success else { return }
            self?.isNowPlayingActive = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                manager.updateNowPlayingInfo()
                self?.setPlaybackState(playing: manager.isPlaying)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                manager.updateNowPlayingInfo()
                self?.setPlaybackState(playing: manager.isPlaying)
            }
        }
    }

    // MARK: - Button builders

    private func makeShuffleButton(isActive: Bool) -> CPNowPlayingImageButton {
        let image = makeButtonImage(symbol: "shuffle", isActive: isActive)
        return CPNowPlayingImageButton(image: image) { _ in
            MusicPlayerManager.shared.toggleShuffle()
            DispatchQueue.main.async {
                self.updateNowPlayingButtons()
            }
        }
    }

    private func makeRepeatButton(mode: MusicPlayerManager.RepeatMode) -> CPNowPlayingImageButton {
        let symbol = mode == .one ? "repeat.1" : "repeat"
        let image = makeButtonImage(symbol: symbol, isActive: mode != .off)
        return CPNowPlayingImageButton(image: image) { _ in
            MusicPlayerManager.shared.cycleRepeatMode()
            DispatchQueue.main.async {
                self.updateNowPlayingButtons()
            }
        }
    }

    private func makeButtonImage(symbol: String, isActive: Bool) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        return UIImage(systemName: symbol, withConfiguration: configuration)?
            .withTintColor(isActive ? .purple : .white, renderingMode: .alwaysOriginal) ?? UIImage()
    }

    // MARK: - Root tab bar

    private func makeRootTabBarTemplate() -> CPTabBarTemplate {
        let songs     = makeSongsListTemplate()
        let albums    = makeAlbumsListTemplate()
        let playlists = makePlaylistsListTemplate()
        let tabBar    = CPTabBarTemplate(templates: [songs, albums, playlists])
        tabBar.delegate = self
        return tabBar
    }

    // MARK: - Dummy item

    private func makeDummyItem(with text: String) -> CPListItem {
        let item = CPListItem(text: text, detailText: nil)
        item.handler = { _, done in
            done()
        }
        return item
    }

    // MARK: - Songs tab

    private func makeSongsListTemplate() -> CPListTemplate {
        let manager = MusicPlayerManager.shared
        songListItems.removeAll()
        currentlyHighlightedSongID = nil

        var items: [CPListItem] = []

        items.append(makeDummyItem(with: "Songs"))

        let songItems = songsViewModel.songs.map { song in
            let item = CPListItem(
                text:       truncate(song.title,  to: 23),
                detailText: "\(truncate(song.artist, to: 20)) • \(fmt(song.duration))",
                image:      resolveArtwork(for: song)
            )
            let playing = manager.isPlaying && song.id == manager.currentSong?.id
            item.isPlaying = playing
            if playing { currentlyHighlightedSongID = song.id }
            songListItems[song.id] = item
            item.handler = { [weak self] _, done in
                self?.songsViewModel.play(song)
                self?.pushNowPlayingIfNeeded()
                done()
            }
            return item
        }
        items.append(contentsOf: songItems)

        let tmpl = CPListTemplate(title: "Songs", sections: [CPListSection(items: items)])
        tmpl.tabImage = UIImage(systemName: "music.quarternote.3")
        return tmpl
    }

    // MARK: - Albums tab

    private func makeAlbumsListTemplate() -> CPListTemplate {
        var items: [CPListItem] = []

        items.append(makeDummyItem(with: "Albums"))

        let albumItems = albumsViewModel.albums.map { album in
            let artwork: UIImage = album.artworkImage ?? placeholderArtwork
            let item = CPListItem(
                text:       truncate(album.name,   to: 23),
                detailText: "\(truncate(album.artist, to: 20)) • \(album.songs.count == 1 ? "\(album.songs.count) Song" : "\(album.songs.count) Songs")",
                image:      artwork
            )
            item.handler = { [weak self] _, done in
                self?.pushAlbumDetail(album: album)
                done()
            }
            return item
        }
        items.append(contentsOf: albumItems)

        let section = CPListSection(
            items: items.isEmpty ? [CPListItem(text: "No Albums", detailText: nil)] : items
        )
        let tmpl = CPListTemplate(title: "Albums", sections: [section])
        tmpl.tabImage = UIImage(systemName: "rectangle.stack.badge.play")
        return tmpl
    }

    private func pushAlbumDetail(album: Album) {
        guard let interface = interfaceController else { return }
        let manager = MusicPlayerManager.shared

        let playAllItem = CPListItem(
            text: "Play All",
            detailText: "\(album.songs.count) songs",
            image: UIImage(systemName: "play.circle.fill")
        )
        playAllItem.handler = { [weak self] _, done in
            MusicPlayerManager.shared.playFromAllSongs(album.songs, fromPlaylist: album.name)
            self?.pushNowPlayingIfNeeded()
            done()
        }
        let shuffleItem = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffleItem.handler = { [weak self] _, done in
            MusicPlayerManager.shared.shufflePlay(playlist: album.songs, fromPlaylist: album.name)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let songItems = album.songs.map { song in
            let item = CPListItem(
                text:       truncate(song.title,  to: 23),
                detailText: "\(truncate(song.artist, to: 20)) • \(fmt(song.duration))",
                image:      resolveArtwork(for: song)
            )
            item.isPlaying = manager.isPlaying && song.id == manager.currentSong?.id
            songListItems[song.id] = item
            item.handler = { [weak self] _, done in
                MusicPlayerManager.shared.playFromAllSongs(
                    album.songs, startAt: song, fromPlaylist: album.name
                )
                self?.pushNowPlayingIfNeeded()
                done()
            }
            return item
        }

        let headerSection = CPListSection(items: [playAllItem, shuffleItem])
        let songsSection  = CPListSection(items: songItems, header: songItems.count == 1 ? "\(songItems.count) Song" : "\(songItems.count) Songs", sectionIndexTitle: "")

        let detail = CPListTemplate(title: album.name, sections: [headerSection, songsSection])
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Playlists tab
    
    private func makePlaylistsListTemplate() -> CPListTemplate {
        let playlists = PlaylistManager.shared.getAllPlaylists()
        var items: [CPListItem] = []

        items.append(makeDummyItem(with: playlists.count == 1 ? "Playlist" : "Playlists"))

        let playlistItems = playlists.map { playlist in
            let songCount = playlist.songPaths.count
            let artwork: UIImage = playlist.coverImage ?? placeholderArtwork
            let item = CPListItem(
                text:       truncate(playlist.name, to: 23),
                detailText: "\(songCount) song\(songCount == 1 ? "" : "s")",
                image:      artwork
            )
            item.handler = { [weak self] _, done in
                self?.pushPlaylistDetail(playlist: playlist)
                done()
            }
            return item
        }
        items.append(contentsOf: playlistItems)

        let section = CPListSection(
            items: items.isEmpty ? [CPListItem(text: "No Playlists", detailText: nil)] : items
        )
        let tmpl = CPListTemplate(title: "Playlists", sections: [section])
        tmpl.tabImage = UIImage(systemName: "music.note.list")
        return tmpl
    }

    private func pushPlaylistDetail(playlist: Playlist) {
        guard let interface = interfaceController else { return }
        let manager   = MusicPlayerManager.shared
        let songs     = PlaylistManager.shared.getSongs(for: playlist)

        let playAllItem = CPListItem(
            text: "Play All",
            detailText: "\(songs.count) songs",
            image: UIImage(systemName: "play.circle.fill")
        )
        playAllItem.handler = { [weak self] _, done in
            MusicPlayerManager.shared.playFromAllSongs(songs, fromPlaylist: playlist.name)
            self?.pushNowPlayingIfNeeded()
            done()
        }
        let shuffleItem = CPListItem(
            text: "Shuffle",
            detailText: nil,
            image: UIImage(systemName: "shuffle")
        )
        shuffleItem.handler = { [weak self] _, done in
            MusicPlayerManager.shared.shufflePlay(playlist: songs, fromPlaylist: playlist.name)
            self?.pushNowPlayingIfNeeded()
            done()
        }

        let songItems = songs.map { song in
            let item = CPListItem(
                text:       truncate(song.title,  to: 23),
                detailText: "\(truncate(song.artist, to: 20)) • \(fmt(song.duration))",
                image:      resolveArtwork(for: song)
            )
            item.isPlaying = manager.isPlaying && song.id == manager.currentSong?.id
            songListItems[song.id] = item
            item.handler = { [weak self] _, done in
                MusicPlayerManager.shared.playFromAllSongs(songs, startAt: song, fromPlaylist: playlist.name)
                self?.pushNowPlayingIfNeeded()
                done()
            }
            return item
        }

        let headerSection = CPListSection(items: [playAllItem, shuffleItem])
        let songsSection  = CPListSection(items: songItems, header: songItems.count == 1 ? "\(songItems.count) Song" : "\(songItems.count) Songs", sectionIndexTitle: "")

        let detail = CPListTemplate(title: playlist.name, sections: [headerSection, songsSection])
        interface.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Shared helpers
    
    private func pushNowPlayingIfNeeded() {
        guard !hasEnteredNowPlaying else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.pushNowPlayingTemplate()
        }
    }

    private func resolveArtwork(for song: Song) -> UIImage {
        if let img = song.artworkImage { return img }
        guard let url = song.resolvedURL ?? song.url else { return placeholderArtwork }
        let asset = AVAsset(url: url)
        for meta in asset.commonMetadata where meta.commonKey?.rawValue == "artwork" {
            if let data = meta.value as? Data, let img = UIImage(data: data) { return img }
        }
        return placeholderArtwork
    }

    private func fmt(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
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
                            .withTintColor(UIColor(AppColors.primary), renderingMode: .alwaysOriginal) {
                note.draw(at: CGPoint(
                    x: (size.width  - note.size.width)  / 2,
                    y: (size.height - note.size.height) / 2
                ))
            }
        }
    }
}
