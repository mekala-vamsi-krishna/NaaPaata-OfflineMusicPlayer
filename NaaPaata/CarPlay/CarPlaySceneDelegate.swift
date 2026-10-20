//
//  CarPlaySceneDelegate.swift
//  NaaPaata
//

import Foundation
import CarPlay
import UIKit
import Combine
import SwiftData

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPTabBarTemplateDelegate {

    var interfaceController: CPInterfaceController?
    
    // Dependencies
    private var libraryViewModel: MusicLibraryViewModel!
    private var dataProvider: CarPlayDataProvider!
    private var templateFactory: CarPlayTemplateFactory!
    private var nowPlayingManager: CarPlayNowPlayingManager!
    
    private var cancellables = Set<AnyCancellable>()
    private var hasEnteredNowPlaying = false
    private var selectedTabIndex = 0
    
    private var isRootTemplateSet = false

    private let themeColor: UIColor = {
        UIColor(named: "AccentColor") ?? .systemPurple
    }()

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
        else { fatalError("Services not initialized") }

        self.libraryViewModel = library
        
        // 1. Initialize Data Layer
        self.dataProvider = CarPlayDataProvider(
            modelContext: container.mainContext,
            folderService: folder,
            libraryViewModel: library
        )
        
        // 2. Initialize UI Factory
        self.templateFactory = CarPlayTemplateFactory(
            themeColor: themeColor,
            placeholderArtwork: defaultArtworkImage()
        )
        setupFactoryActions()
        
        // 3. Initialize Now Playing Manager
        self.nowPlayingManager = CarPlayNowPlayingManager(libraryViewModel: library)
        
        // 4. Observe ViewModel for List Indicators
        observeViewModel()

        Task {
            await library.loadLibrary()
            let root = templateFactory.makeRootTabBarTemplate(dataProvider: dataProvider)
            root.delegate = self
            
            await MainActor.run {
                interfaceController.setRootTemplate(root, animated: true) { [weak self] success, error in
                    guard let self else { return }
                    
                    if success {
                        self.isRootTemplateSet = true
                        self.selectTab(at: self.selectedTabIndex, in: root)
                        
                        if self.libraryViewModel.currentSong != nil {
                            self.pushNowPlayingIfNeeded()
                        }
                    }
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
        self.isRootTemplateSet = false // Reset on disconnect
        templateFactory.clearItems()
    }
    
    // MARK: - Factory Action Injection
    
    private func setupFactoryActions() {
        templateFactory.onPlaySong = { [weak self] song, queue in
            self?.libraryViewModel.play(song, in: queue)
        }
        
        templateFactory.onPlayAll = { [weak self] songs in
            self?.libraryViewModel.playAll(songs)
        }
        
        templateFactory.onShuffleAll = { [weak self] songs in
            self?.libraryViewModel.shuffleAll(songs)
        }
        
        templateFactory.onPushTemplate = { [weak self] template in
            self?.interfaceController?.pushTemplate(template, animated: true, completion: nil)
        }
        
        templateFactory.onShowNowPlaying = { [weak self] in
            self?.pushNowPlayingIfNeeded()
        }
        
        templateFactory.onShowRecents = { [weak self] in
            guard let self else { return }
            self.templateFactory.pushRecentsList(dataProvider: self.dataProvider)
        }
    }

    // MARK: - View Model Observation

    private func observeViewModel() {
        // Update playing indicators in lists when play/pause changes
        libraryViewModel.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                guard let self else { return }
                self.templateFactory.updatePlayingIndicator(
                    currentSong: self.libraryViewModel.currentSong,
                    isPlaying: isPlaying
                )
            }
            .store(in: &cancellables)

        // Handle track changes and navigation
        libraryViewModel.$currentSong
            .receive(on: RunLoop.main)
            .sink { [weak self] song in
                guard let self else { return }
                self.templateFactory.updatePlayingIndicator(
                    currentSong: song,
                    isPlaying: self.libraryViewModel.isPlaying
                )
                
                if song != nil, !self.hasEnteredNowPlaying {
                    self.pushNowPlayingIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation
    
    private func selectTab(at index: Int, in tabBar: CPTabBarTemplate) {
        guard index < tabBar.templates.count else { return }
        tabBar.selectTemplate(at: index)
    }

    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        if let index = tabBarTemplate.templates.firstIndex(where: { $0 === selectedTemplate }) {
            selectedTabIndex = index
        }
    }

    private func pushNowPlayingIfNeeded() {
        guard !hasEnteredNowPlaying, let interface = interfaceController else { return }
        
        guard isRootTemplateSet else { return }
        
        hasEnteredNowPlaying = true
        libraryViewModel.updateNowPlayingInfo()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            interface.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
        }
    }

    // MARK: - Helpers

    private func defaultArtworkImage() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8).fill()
            let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            if let note = UIImage(systemName: "music.note", withConfiguration: cfg)?.withTintColor(themeColor, renderingMode: .alwaysOriginal) {
                note.draw(at: CGPoint(x: (size.width - note.size.width) / 2, y: (size.height - note.size.height) / 2))
            }
        }
    }
}
