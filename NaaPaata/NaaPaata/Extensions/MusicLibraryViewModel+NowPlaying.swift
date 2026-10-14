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
    // MARK: - Remote Command Center
    func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)

        center.playCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil, !self.isPlaying else {
                return .commandFailed
            }
            self.playerService.play()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            guard let self, self.isPlaying else {
                return .commandFailed
            }
            self.playerService.pause()
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else {
                return .commandFailed
            }
            self.playNext()
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, self.currentSong != nil else {
                return .commandFailed
            }
            self.playPrevious()
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let event = event as? MPChangePlaybackPositionCommandEvent,
                  let duration = self.currentSong?.duration,
                  duration > 0
            else {
                return .commandFailed
            }

            let progress = event.positionTime / duration
            self.seek(toProgress: progress)
            return .success
        }
    }

    // MARK: - Now Playing info
    func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,

            MPMediaItemPropertyPlaybackDuration: NSNumber(value: song.duration ?? 0),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: progressStore.elapsed),
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: isPlaying ? 1.0 : 0.0),
        ]

        if let data = song.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
