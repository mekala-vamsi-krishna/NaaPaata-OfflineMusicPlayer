//
//  MusicLibraryViewModel+NowPlaying.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation
import MediaPlayer
import UIKit

extension MusicLibraryViewModel {
    
    func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        
        // Remove ALL old targets
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)
        center.changeShuffleModeCommand.removeTarget(nil)
        center.changeRepeatModeCommand.removeTarget(nil)
        
        // Enable ALL commands
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true
        center.changeShuffleModeCommand.isEnabled = true
        center.changeRepeatModeCommand.isEnabled = true
        
        // Add Handlers
        center.playCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else { return .commandFailed }
            self.playerService.play()
            return .success
        }
        
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else { return .commandFailed }
            self.playerService.pause()
            return .success
        }
        
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }
        
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else { return .commandFailed }
            self.playNext()
            return .success
        }
        
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else { return .commandFailed }
            self.playPrevious()
            return .success
        }
        
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent,
                  let duration = self.currentSong?.duration, duration > 0 else { return .commandFailed }
            self.seek(toProgress: event.positionTime / duration)
            return .success
        }
        
        center.changeShuffleModeCommand.addTarget { [weak self] event in
            guard let self, let shuffleEvent = event as? MPChangeShuffleModeCommandEvent else { return .commandFailed }
            let isCarPlayShuffleOn = shuffleEvent.shuffleType != .off
            Task { @MainActor in
                if isCarPlayShuffleOn != self.isShuffled { self.toggleShuffle() }
            }
            return .success
        }
        
        center.changeRepeatModeCommand.addTarget { [weak self] event in
            guard let self, let repeatEvent = event as? MPChangeRepeatModeCommandEvent else { return .commandFailed }
            let targetMode: RepeatMode
            switch repeatEvent.repeatType {
            case .off: targetMode = .off
            case .one: targetMode = .one
            case .all: targetMode = .all
            @unknown default: targetMode = .off
            }
            Task { @MainActor in
                var attempts = 0
                while self.repeatMode != targetMode && attempts < 3 {
                    self.cycleRepeatMode()
                    attempts += 1
                }
            }
            return .success
        }
    }

    func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        
        info[MPMediaItemPropertyTitle] = song.title
        info[MPMediaItemPropertyArtist] = song.artist
        info[MPMediaItemPropertyAlbumTitle] = song.album
        info[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: song.duration ?? 0)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: progressStore.elapsed)
        info[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: isPlaying ? 1.0 : 0.0)
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = NSNumber(value: 1.0)
        info[MPNowPlayingInfoPropertyIsLiveStream] = false

        if let data = song.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        } else {
            info.removeValue(forKey: MPMediaItemPropertyArtwork)
            
             let placeholder = UIImage(named: "AppLogo") ?? UIImage(systemName: "music.note")!
             info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: placeholder.size) { _ in placeholder }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
