//
//  CarPlayNowPlayingManager.swift
//  NaaPaata
//

import CarPlay
import Combine
import UIKit

@MainActor
final class CarPlayNowPlayingManager {
    private let libraryViewModel: MusicLibraryViewModel
    private var cancellables = Set<AnyCancellable>()
    private var template: CPNowPlayingTemplate { .shared }
    
    init(libraryViewModel: MusicLibraryViewModel) {
        self.libraryViewModel = libraryViewModel
        setupNowPlayingButtons()
        observeViewModel()
    }
    
    private func setupNowPlayingButtons() {
        // SHUFFLE BUTTON
        let shuffleImage = UIImage(systemName: "shuffle")?.withRenderingMode(.alwaysTemplate)
        let shuffleButton = CPNowPlayingImageButton(image: shuffleImage ?? UIImage()) { [weak self] _ in
            self?.libraryViewModel.toggleShuffle()
        }
        // Setting isSelected = true triggers the native capsule highlight
        shuffleButton.isSelected = libraryViewModel.isShuffled

        // REPEAT BUTTON
        let repeatSymbol = libraryViewModel.repeatMode == .one ? "repeat.1" : "repeat"
        let repeatImage = UIImage(systemName: repeatSymbol)?.withRenderingMode(.alwaysTemplate)
        let repeatButton = CPNowPlayingImageButton(image: repeatImage ?? UIImage()) { [weak self] _ in
            self?.libraryViewModel.cycleRepeatMode()
        }
        repeatButton.isSelected = libraryViewModel.repeatMode != .off

        // FAVOURITE BUTTON
        let isFav = libraryViewModel.isCurrentSongFavourite
        let starSymbol = isFav ? "star.fill" : "star"
        let starImage = UIImage(systemName: starSymbol)?.withRenderingMode(.alwaysTemplate)
        let favouriteButton = CPNowPlayingImageButton(image: starImage ?? UIImage()) { [weak self] _ in
            self?.libraryViewModel.toggleFavourite()
        }
        favouriteButton.isSelected = isFav

        // Dispatch asynchronously so CarPlay registers the new button array
        DispatchQueue.main.async {
            self.template.updateNowPlayingButtons([shuffleButton, repeatButton, favouriteButton])
        }
    }

    private func observeViewModel() {
        // Observe ALL THREE states to ensure CarPlay stays perfectly in sync
        libraryViewModel.$isCurrentSongFavourite
            .receive(on: RunLoop.main)
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.setupNowPlayingButtons() }
            .store(in: &cancellables)

        libraryViewModel.$repeatMode
            .receive(on: RunLoop.main)
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.setupNowPlayingButtons() }
            .store(in: &cancellables)

        libraryViewModel.$isShuffled
            .receive(on: RunLoop.main)
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.setupNowPlayingButtons() }
            .store(in: &cancellables)
    }
}
