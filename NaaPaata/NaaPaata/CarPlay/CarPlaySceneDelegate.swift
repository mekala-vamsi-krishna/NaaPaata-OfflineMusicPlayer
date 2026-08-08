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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool { true }
}

class CarPlaySceneDelegate: UIResponder,
                            CPTemplateApplicationSceneDelegate,
                            MusicPlayerManagerDelegate,
                            CPTabBarTemplateDelegate {

    // MARK: - Properties
    var interfaceController: CPInterfaceController?
    private lazy var placeholderArtwork = defaultArtworkImage()
    let songsViewModel = SongsViewModel()

    private var isNowPlayingActive   = false
    private var hasEnteredNowPlaying = false
    private var selectedTabIndex     = 0

    private var songListItems: [UUID: CPListItem] = [:]
    private weak var songsListTemplate: CPListTemplate?
    private var currentlyHighlightedSongID: UUID?

    private var nowPlayingTemplate: CPNowPlayingTemplate { .shared }

    // MARK: - Scene Lifecycle
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        MusicPlayerManager.shared.delegate = self

        songsViewModel.setup(modelContext: PersistenceController.shared.container.mainContext)

        Task {
            await songsViewModel.loadSongs()
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
    }

    func musicPlayerManagerDidChangePlaybackState(_ manager: MusicPlayerManager) {
        updateNowPlayingButtons()
        updatePlayingIndicators(currentSong: manager.currentSong, isPlaying: manager.isPlaying)
    }

    func musicPlayerManagerDidChangeShuffle(_ manager: MusicPlayerManager) {
        updateNowPlayingButtons()
    }

    func musicPlayerManagerDidChangeRepeat(_ manager: MusicPlayerManager) {
        updateNowPlayingButtons()
    }

    // MARK: - CPTabBarTemplateDelegate
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        if let index = tabBarTemplate.templates.firstIndex(where: { $0 === selectedTemplate }) {
            selectedTabIndex = index
        }
    }

    // MARK: - list update
    private func updatePlayingIndicators(currentSong: Song?, isPlaying: Bool) {
        let newHighlightedID = isPlaying ? currentSong?.id : nil

        guard newHighlightedID != currentlyHighlightedSongID else { return }

        if let previousID = currentlyHighlightedSongID, let previousItem = songListItems[previousID] {
            previousItem.isPlaying = false
        }
        if let newID = newHighlightedID, let newItem = songListItems[newID] {
            newItem.isPlaying = true
        }
        currentlyHighlightedSongID = newHighlightedID
    }

    // MARK: - UI Updates
    private func selectTab(at index: Int, in tabBar: CPTabBarTemplate) {
        guard index < tabBar.templates.count else { return }
        tabBar.selectTemplate(at: index)
    }

    private func updateNowPlayingButtons() {
        let manager    = MusicPlayerManager.shared
        let shuffleBtn = makeShuffleButton(isActive: manager.shuffleIsActive)
        let repeatBtn  = makeRepeatButton(mode: manager.currentRepeatMode)
        nowPlayingTemplate.updateNowPlayingButtons([shuffleBtn, repeatBtn])
    }

    // MARK: - Navigation
    private func pushNowPlayingTemplate() {
        guard let interface = interfaceController else { return }
        hasEnteredNowPlaying = true

        MusicPlayerManager.shared.updateNowPlayingInfo()
        updateNowPlayingButtons()

        interface.pushTemplate(nowPlayingTemplate, animated: true) { [weak self] success, _ in
            guard success else { return }
            self?.isNowPlayingActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                MusicPlayerManager.shared.updateNowPlayingInfo()
            }
        }
    }

    // MARK: - Button Builders
    private func makeShuffleButton(isActive: Bool) -> CPNowPlayingImageButton {
        let symbolName = isActive ? "shuffle.circle.fill" : "shuffle"
        let image = UIImage(systemName: symbolName)
        return CPNowPlayingImageButton(image: image ?? placeholderArtwork) { _ in
            MusicPlayerManager.shared.toggleShuffle()
        }
    }

    private func makeRepeatButton(mode: MusicPlayerManager.RepeatMode) -> CPNowPlayingImageButton {
        let symbolName: String
        switch mode {
        case .off: symbolName = "repeat"
        case .one: symbolName = "repeat.1.circle.fill"
        case .all: symbolName = "repeat.circle.fill"
        }
        let image = UIImage(systemName: symbolName)
        return CPNowPlayingImageButton(image: image ?? placeholderArtwork) { _ in
            MusicPlayerManager.shared.cycleRepeatMode()
        }
    }
    
    // MARK: - Templates
    private func makeRootTabBarTemplate() -> CPTabBarTemplate {
        let songs     = makeSongsListTemplate()
        let albums    = makeAlbumsListTemplate()
        let playlists = makePlaylistsListTemplate()
        songsListTemplate = songs
        let tabBar = CPTabBarTemplate(templates: [songs, albums, playlists])
        tabBar.delegate = self
        return tabBar
    }

    private func makeSongsListTemplate() -> CPListTemplate {
        let manager = MusicPlayerManager.shared
        songListItems.removeAll()
        currentlyHighlightedSongID = nil

        let items: [CPListItem] = songsViewModel.songs.map { song in
            let artwork: UIImage = {
                if let img = song.artworkImage { return img }
                guard let url = song.resolvedURL ?? song.url else { return placeholderArtwork }
                let asset = AVAsset(url: url)
                for meta in asset.commonMetadata
                where meta.commonKey?.rawValue == "artwork" {
                    if let data = meta.value as? Data, let img = UIImage(data: data) { return img }
                }
                return placeholderArtwork
            }()

            let item = CPListItem(
                text:       truncate(song.title,  maxLength: 23),
                detailText: "\(truncate(song.artist, maxLength: 20)) • \(formatDuration(song.duration))",
                image:      artwork
            )


            let isThisSongPlaying = manager.isPlaying && song.id == manager.currentSong?.id
            item.isPlaying = isThisSongPlaying
            if isThisSongPlaying { currentlyHighlightedSongID = song.id }

            songListItems[song.id] = item

            item.handler = { [weak self] _, completion in
                let shouldPush = !(self?.hasEnteredNowPlaying ?? false)
                self?.songsViewModel.play(song)
                if shouldPush {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.pushNowPlayingTemplate()
                    }
                }
                completion()
            }
            return item
        }

        let template = CPListTemplate(
            title:    "Songs",
            sections: [CPListSection(items: items)]
        )
        template.tabImage = UIImage(systemName: "music.quarternote.3")
        return template
    }

    private func makeAlbumsListTemplate() -> CPListTemplate {
        let template = CPListTemplate(
            title:    "Albums",
            sections: [CPListSection(items: [CPListItem(text: "No Albums", detailText: nil)])]
        )
        template.tabImage = UIImage(systemName: "rectangle.stack.badge.play")
        return template
    }

    private func makePlaylistsListTemplate() -> CPListTemplate {
        let template = CPListTemplate(
            title:    "Playlists",
            sections: [CPListSection(items: [CPListItem(text: "No Playlists", detailText: nil)])]
        )
        template.tabImage = UIImage(systemName: "music.note.list")
        return template
    }

    // MARK: - Helpers
    private func formatDuration(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    private func truncate(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength - 1)) + "…"
    }

    private func defaultArtworkImage() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8).fill()
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            if let note = UIImage(systemName: "music.note", withConfiguration: config)?
                            .withTintColor(UIColor(AppColors.primary), renderingMode: .alwaysOriginal) {
                note.draw(at: CGPoint(
                    x: (size.width  - note.size.width)  / 2,
                    y: (size.height - note.size.height) / 2
                ))
            }
        }
    }
}
