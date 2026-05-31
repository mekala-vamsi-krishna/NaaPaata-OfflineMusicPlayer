//
//  MusicPlayerManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/21/25.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import Foundation

final class MusicPlayerManager: NSObject, ObservableObject {
    static let shared = MusicPlayerManager()
    
    // MARK: - Published Properties
    @Published var artworkImage: UIImage?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSong: Song?
    @Published var currentRepeatMode: RepeatMode = .off
    @Published var shuffleIsActive: Bool = false
    
    // MARK: - Audio Engine Properties
    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var equalizer: AVAudioUnitEQ!
    private var audioFile: AVAudioFile?
    
    private var timer: Timer?
    private var seekFrame: AVAudioFramePosition = 0
    private var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) else {
            return seekFrame
        }
        return seekFrame + playerTime.sampleTime
    }
    
    // MARK: - Repeat Mode Enum
    enum RepeatMode {
        case off      // No repeat
        case one      // Repeat current song
        case all      // Repeat entire playlist
    }
    
    // MARK: - Playlist Management
    var allSongs: [Song] = []
    private var originalPlaylist: [Song] = []  // Store original order
    private var shuffledPlaylist: [Song] = []  // Store shuffled order when shuffle is active
    private var playQueue: [Song] = []
    private var currentIndex: Int = 0
    private var currentPlaylistName: String? = nil
    private var isPlayingFromPlaylist: Bool = false
    
    // Cache for artwork
    private let artworkCache = NSCache<NSString, UIImage>()
    
    // MARK: - Equalizer Frequencies
    override init() {
        super.init()
        setupAudioEngine()
        setupNotifications()
    }
    
    private func setupAudioEngine() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        // Initialize EQ with 9 bands
        equalizer = AVAudioUnitEQ(numberOfBands: 9)
        
        // Configure Bands
        let frequencies: [Float] = [60, 150, 400, 1000, 2400, 15000, 20000]
        
        // Band 0: Bass Knob (Low Shelf at ~100Hz)
        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = 100
        equalizer.bands[0].bypass = false
        
        // Bands 1-7: Sliders (Parametric)
        for (index, freq) in frequencies.enumerated() {
            let bandIndex = index + 1
            equalizer.bands[bandIndex].filterType = .parametric
            equalizer.bands[bandIndex].frequency = freq
            equalizer.bands[bandIndex].bandwidth = 1.0
            equalizer.bands[bandIndex].bypass = false
        }
        
        // Band 8: Treble Knob (High Shelf at ~10kHz)
        equalizer.bands[8].filterType = .highShelf
        equalizer.bands[8].frequency = 10000
        equalizer.bands[8].bypass = false
        
        engine.attach(playerNode)
        engine.attach(equalizer)
        
        // Connect Nodes: Player -> EQ -> MainMixer
        engine.connect(playerNode, to: equalizer, format: nil)
        engine.connect(equalizer, to: engine.mainMixerNode, format: nil)
        
        // Setup Audio Session
        setupAudioSession()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            if isPlaying {
                playerNode.pause()
                isPlaying = false
            }
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? engine.start()
                    playerNode.play()
                    isPlaying = true
                    updateNowPlayingInfo()
                }
            }
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        switch reason {
        case .oldDeviceUnavailable:
            if isPlaying {
                playerNode.pause()
                isPlaying = false
                updateNowPlayingInfo()
            }
        default: break
        }
    }
    
    // MARK: - Equalizer Control Methods
    func updateEQ(settings: EqualizerSettings) {
        equalizer.bypass = !settings.isEnabled
        
        if !settings.isEnabled { return }
        
        // Pre-Amp (Global Gain)
        if settings.isPreAmpEnabled {
            equalizer.globalGain = Float(settings.preAmpValue)
        } else {
            equalizer.globalGain = 0
        }
        
        // Bass Knob (Band 0)
        if settings.isBassEnabled {
            equalizer.bands[0].gain = Float(settings.bassValue)
            equalizer.bands[0].bypass = false
        } else {
            equalizer.bands[0].gain = 0
            equalizer.bands[0].bypass = true
        }
        
        // Sliders (Bands 1-7)
        for (index, value) in settings.bands.enumerated() {
            let bandIndex = index + 1
            if bandIndex < equalizer.bands.count {
                equalizer.bands[bandIndex].gain = Float(value)
            }
        }
        
        // Treble Knob (Band 8)
        if settings.isTrebleEnabled {
            equalizer.bands[8].gain = Float(settings.trebleValue)
            equalizer.bands[8].bypass = false
        } else {
            equalizer.bands[8].gain = 0
            equalizer.bands[8].bypass = true
        }
    }
    
    func setVolume(_ volume: Double) {
        engine.mainMixerNode.outputVolume = Float(volume)
    }
    
    // MARK: - Playback State
    private var playbackToken: UUID?
    
    // MARK: - Playback Methods
    func playSong(_ song: Song) {
        currentSong = song
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        do {
            guard let fileURL = song.resolvedURL ?? song.url as URL? else {
                print("Error: Unable to resolve song URL")
                return
            }
            
            audioFile = try AVAudioFile(forReading: fileURL)
            guard let audioFile = audioFile else { return }
            
            playerNode.stop()
            
            let token = UUID()
            playbackToken = token
            
            seekFrame = 0
            playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handlePlaybackFinished(token: token)
                }
            }
            
            setupRemoteTransportControls()
            
            playerNode.play()
            isPlaying = true
            duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            
            if let artwork = song.artworkImage {
                artworkImage = artwork
            } else {
                artworkImage = getArtwork(for: song)
            }
            
            updateNowPlayingInfo()
            startTimer()
            
        } catch {
            print("Error playing song: \(error.localizedDescription)")
        }
        
        updateNowPlayingInfo()
    }
    
    private func handlePlaybackFinished(token: UUID) {
        guard token == playbackToken else { return }
        
        if isPlaying {
            switch currentRepeatMode {
            case .off:
                playNext()
            case .one:
                if let current = currentSong {
                    playSong(current)
                }
            case .all:
                playNext()
            }
        }
    }
    
    func playFromAllSongs(_ songs: [Song], startAt song: Song? = nil, fromPlaylist playlistName: String? = nil) {
        allSongs = songs
        originalPlaylist = songs
        shuffledPlaylist = []
        shuffleIsActive = false
        playQueue = []
        currentPlaylistName = playlistName
        isPlayingFromPlaylist = (playlistName != nil)
        currentRepeatMode = .off

        if let startSong = song {
            currentSong = startSong
            if let index = songs.firstIndex(where: { $0.url == startSong.url }) {
                currentIndex = index
                playSong(startSong)
            } else {
                currentIndex = 0
                if let first = songs.first {
                    currentSong = first
                    playSong(first)
                }
            }
        } else if let first = songs.first {
            currentSong = first
            currentIndex = 0
            playSong(first)
        }
    }
    
    // MARK: - Play Next in Queue
    func addToQueueNext(_ song: Song) {
        guard !allSongs.isEmpty else {
            playQueue = [song]
            return
        }

        let safeIndex = (0..<allSongs.count).contains(currentIndex) ? currentIndex : -1

        let remaining: [Song]
        if safeIndex >= 0 && safeIndex + 1 < allSongs.count {
            remaining = Array(allSongs[(safeIndex + 1)...])
        } else {
            remaining = []
        }

        playQueue = remaining
        playQueue.insert(song, at: 0)
    }
    
    func playNext() {
        if !playQueue.isEmpty {
            let nextSong = playQueue.removeFirst()
            if let originalIndex = allSongs.firstIndex(where: { $0.url == nextSong.url }) {
                currentIndex = originalIndex
            }
            playSong(nextSong)
        } else if !allSongs.isEmpty {
            let playlistToUse = shuffleIsActive ? (shuffledPlaylist.isEmpty ? allSongs : shuffledPlaylist) : allSongs
            
            guard !playlistToUse.isEmpty else { return }
            
            switch currentRepeatMode {
            case .all:
                currentIndex = (currentIndex + 1) % playlistToUse.count
                let nextSong = playlistToUse[currentIndex]
                playSong(nextSong)
            case .one:
                if let current = currentSong {
                    playSong(current)
                }
            case .off:
                if currentIndex < playlistToUse.count - 1 {
                    currentIndex += 1
                    let nextSong = playlistToUse[currentIndex]
                    playSong(nextSong)
                } else {
                    stop()
                }
            }
        }
    }
    
    func playPrevious() {
        let playlistToUse = shuffleIsActive ? (shuffledPlaylist.isEmpty ? allSongs : shuffledPlaylist) : allSongs
        guard !playlistToUse.isEmpty else { return }
        
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        
        if currentRepeatMode == .one {
            if let current = currentSong {
                playSong(current)
            }
        } else {
            currentIndex = (currentIndex - 1 + playlistToUse.count) % playlistToUse.count
            playSong(playlistToUse[currentIndex])
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            playerNode.pause()
            isPlaying = false
        } else {
            if !engine.isRunning {
                try? engine.start()
            }
            playerNode.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }
    
    func pause() {
        if isPlaying {
            playerNode.pause()
            isPlaying = false
            updateNowPlayingInfo()
        }
    }
    
    func stop() {
        playbackToken = nil
        playerNode.stop()
        engine.stop()
        isPlaying = false
        currentSong = nil
        artworkImage = nil
        stopTimer()
        PlaybackStateService.shared.clearPlaybackState()
    }
    
    // MARK: - Unified Shuffle Implementation
    func toggleShuffle() {
        if shuffleIsActive {
            // Turning shuffle OFF - restore original order
            deactivateShuffle()
        } else {
            // Turning shuffle ON - create shuffled playlist
            activateShuffle()
        }
        
        // Industry standard: Turning on shuffle disables repeat
        if shuffleIsActive && currentRepeatMode != .off {
            currentRepeatMode = .off
        }
    }
    
    private func activateShuffle() {
        guard !allSongs.isEmpty else { return }
        
        let currentSong = getCurrentSong()
        
        if let currentSong = currentSong {
            // Keep current song at position 0, shuffle the rest
            var songsToShuffle = allSongs.filter { $0.id != currentSong.id }
            songsToShuffle.shuffle()
            shuffledPlaylist = [currentSong] + songsToShuffle
            currentIndex = 0
        } else {
            // No current song, shuffle everything
            shuffledPlaylist = allSongs.shuffled()
            currentIndex = 0
        }
        
        shuffleIsActive = true
    }
    
    private func deactivateShuffle() {
        // Restore original order while maintaining current song position
        guard let currentSong = getCurrentSong(),
              let originalIndex = originalPlaylist.firstIndex(where: { $0.id == currentSong.id }) else {
            shuffledPlaylist = originalPlaylist
            currentIndex = 0
            shuffleIsActive = false
            return
        }
        
        shuffledPlaylist = originalPlaylist
        currentIndex = originalIndex
        shuffleIsActive = false
    }
    
    private func getCurrentSong() -> Song? {
        let activePlaylist = shuffleIsActive ? shuffledPlaylist : originalPlaylist
        guard currentIndex >= 0 && currentIndex < activePlaylist.count else { return nil }
        return activePlaylist[currentIndex]
    }
    
    // MARK: - Unified Repeat Implementation
    func cycleRepeatMode() {
        // Industry standard: Turning on repeat disables shuffle
        if shuffleIsActive {
            deactivateShuffle()
        }
        
        // Cycle through repeat modes: off → all → one → off
        switch currentRepeatMode {
        case .off:
            currentRepeatMode = .all
        case .all:
            currentRepeatMode = .one
        case .one:
            currentRepeatMode = .off
        }
    }
    
    // MARK: - Shuffle Playlist
    func shufflePlay(playlist: [Song], fromPlaylist playlistName: String? = nil) {
        allSongs = playlist
        originalPlaylist = playlist
        shuffledPlaylist = playlist.shuffled()
        shuffleIsActive = true
        currentRepeatMode = .off
        
        currentPlaylistName = playlistName
        isPlayingFromPlaylist = (playlistName != nil)
        playQueue = []
        
        currentIndex = 0
        if let songToPlay = shuffledPlaylist.first {
            playSong(songToPlay)
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if let nodeTime = self.playerNode.lastRenderTime,
               let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime),
               let file = self.audioFile {
                
                let sampleRate = file.processingFormat.sampleRate
                let currentFrame = self.seekFrame + playerTime.sampleTime
                let time = Double(currentFrame) / sampleRate
                
                self.currentTime = time
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Persistent Playback State Methods
    func saveCurrentPlaybackState() {
        guard let currentSong = currentSong else { return }
        
        let playbackState = PlaybackState(
            song: currentSong,
            position: currentTime,
            isPlaying: isPlaying
        )
        PlaybackStateService.shared.savePlaybackState(playbackState)
    }
    
    func restoreLastPlaybackState() {
        guard let playbackState = PlaybackStateService.shared.loadPlaybackState() else { return }
        
        guard let songURL = URL(string: playbackState.songURL),
              FileManager.default.fileExists(atPath: songURL.path) else {
            PlaybackStateService.shared.clearPlaybackState()
            return
        }
        
        let restoredSong = Song(
            url: songURL,
            title: playbackState.songTitle,
            artist: playbackState.songArtist,
            duration: 0,
            artworkImage: playbackState.artworkData != nil ? UIImage(data: playbackState.artworkData!) : nil
        )
        
        playSong(restoredSong)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if playbackState.playbackPosition > 0 {
                self.seek(to: playbackState.playbackPosition)
            }
            
            if self.isPlaying {
                self.togglePlayPause()
            }
        }
    }
    
    // MARK: - Artwork Extraction
    func getArtwork(for song: Song) -> UIImage {
        if let artwork = song.artworkImage { return artwork }
        guard let fileURL = song.resolvedURL ?? song.url as URL? else {
            return generateDefaultArtwork()
        }
        let asset = AVAsset(url: fileURL)
        for meta in asset.commonMetadata {
            if meta.commonKey?.rawValue == "artwork",
               let data = meta.value as? Data,
               let image = UIImage(data: data) {
                return image
            }
        }
        return generateDefaultArtwork()
    }
    
    func loadArtworkAsync(for song: Song) async -> UIImage {
        let key = NSString(string: song.urlString)
        if let cached = artworkCache.object(forKey: key) { return cached }
        if let artwork = song.artworkImage {
            artworkCache.setObject(artwork, forKey: key)
            return artwork
        }
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return UIImage(systemName: "music.note")! }
            guard let fileURL = song.resolvedURL ?? song.url else {
                return self.generateDefaultArtwork()
            }
            let asset = AVAsset(url: fileURL)
            var image: UIImage?
            let metadata: [AVMetadataItem]? = try? await asset.load(.commonMetadata)
            if let metadata = metadata {
                for meta in metadata {
                    if meta.commonKey?.rawValue == "artwork",
                       let data = try? await meta.load(.value) as? Data,
                       let img = UIImage(data: data) {
                        image = img
                        break
                    }
                }
            }
            let result = image ?? self.generateDefaultArtwork()
            self.artworkCache.setObject(result, forKey: key)
            return result
        }.value
    }
    
    private func generateDefaultArtwork() -> UIImage {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let colors = [UIColor(AppColors.primary).cgColor, UIColor(AppColors.primary).cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
            if let symbolImage = UIImage(systemName: "music.note")?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let symbolSize = CGSize(width: size.width * 0.5, height: size.height * 0.5)
                let symbolOrigin = CGPoint(x: (size.width - symbolSize.width) / 2, y: (size.height - symbolSize.height) / 2)
                symbolImage.draw(in: CGRect(origin: symbolOrigin, size: symbolSize))
            }
        }
    }
    
    func loadSong(from url: URL) -> Song {
        let asset = AVAsset(url: url)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var duration: TimeInterval = 0
        var artwork: UIImage? = nil
        duration = CMTimeGetSeconds(asset.duration)
        for item in asset.commonMetadata {
            guard let key = item.commonKey else { continue }
            switch key {
            case .commonKeyTitle: if let value = item.stringValue { title = value }
            case .commonKeyArtist: if let value = item.stringValue { artist = value }
            case .commonKeyArtwork: if let data = item.dataValue, let image = UIImage(data: data) { artwork = image }
            default: break
            }
        }
        return Song(url: url, title: title, artist: artist, duration: duration, artworkImage: artwork)
    }
    
    func delete(song: Song) {
        if currentSong == song {
            stop()
            PlaybackStateService.shared.clearPlaybackState()
        }
        allSongs.removeAll { $0 == song }
        playQueue.removeAll { $0 == song }
        guard let fileURL = song.resolvedURL ?? song.url else {
            print("Failed to delete file: invalid song URL")
            return
        }
        do {
            try FileManager.default.removeItem(at: fileURL)
            NotificationCenter.default.post(name: .songDeleted, object: nil, userInfo: ["song": song])
        } catch { print("Failed to delete file: \(error.localizedDescription)") }
        if !allSongs.isEmpty { playNext() }
    }
    
    func seek(to time: TimeInterval) {
        guard let audioFile = audioFile else { return }
        
        let sampleRate = audioFile.processingFormat.sampleRate
        let newFrame = AVAudioFramePosition(time * sampleRate)
        let frameCount = AVAudioFrameCount(audioFile.length - newFrame)
        
        if frameCount > 0 {
            playerNode.stop()
            
            let token = UUID()
            playbackToken = token
            
            if frameCount > 1000 {
                playerNode.scheduleSegment(
                    audioFile,
                    startingFrame: newFrame,
                    frameCount: frameCount,
                    at: nil
                ) { [weak self] in
                    DispatchQueue.main.async {
                        self?.handlePlaybackFinished(token: token)
                    }
                }
            }
            
            seekFrame = newFrame
            
            if isPlaying {
                playerNode.play()
            }
            
            currentTime = time
            updateNowPlayingInfo()
        }
    }
    
    // MARK: - Lock Screen
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio Session Error: \(error.localizedDescription)") }
    }
    
    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        var info: [String : Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let img = currentSong?.artworkImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        } else {
            let fallback = UIImage(systemName: "music.note")!
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 600, height: 600)) { _ in fallback }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func setupRemoteTransportControls() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = true
        cc.pauseCommand.isEnabled = true
        cc.nextTrackCommand.isEnabled = true
        cc.previousTrackCommand.isEnabled = true
        cc.changePlaybackPositionCommand.isEnabled = true
        
        cc.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        cc.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }
}

extension Notification.Name {
    static let songDeleted = Notification.Name("songDeleted")
}
