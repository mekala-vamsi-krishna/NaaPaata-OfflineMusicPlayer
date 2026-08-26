import SwiftUI
import Combine
import SwiftData
import AVFoundation
import MediaPlayer
import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

protocol MusicPlayerManagerDelegate: AnyObject {
    func musicPlayerManager(_ manager: MusicPlayerManager, didChangeCurrentSong song: Song?)
    func musicPlayerManagerDidChangePlaybackState(_ manager: MusicPlayerManager)
    func musicPlayerManagerDidChangeShuffle(_ manager: MusicPlayerManager)
    func musicPlayerManagerDidChangeRepeat(_ manager: MusicPlayerManager)
}

final class PlaybackClock: ObservableObject {
    @Published var currentTime: TimeInterval = 0
}

final class MusicPlayerManager: NSObject, ObservableObject {
    static let shared = MusicPlayerManager()
    
    private var allSongs: [Song] = []
    private var originalPlaylist: [Song] = []
    private var shuffledPlaylist: [Song] = []
    private var playQueue: [Song] = []

    private var modelContainer: ModelContainer?

    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    
    private var currentPlaylistName: String?
    private var isPlayingFromPlaylist: Bool = false
    private var currentIndex: Int = 0
    
    // Cache Artwork
    private let artworkCache = NSCache<NSString, UIImage>()
    
    // MARK: - Published Properties
    @Published var artworkImage: UIImage?
    
    weak var delegate: MusicPlayerManagerDelegate?
    
    @Published var isPlaying: Bool = false {
        didSet {
            delegate?.musicPlayerManagerDidChangePlaybackState(self)
            updateNowPlayingInfo()
            updateWidgetData()
        }
    }
    @Published var duration: TimeInterval = 0
    @Published var currentSong: Song? {
        didSet {
            delegate?.musicPlayerManager(self, didChangeCurrentSong: currentSong)
        }
    }

    let clock = PlaybackClock()
    var currentTime: TimeInterval {
        get { clock.currentTime }
        set { clock.currentTime = newValue }
    }
    
    @Published var shuffleIsActive: Bool = false {
        didSet {
            delegate?.musicPlayerManagerDidChangeShuffle(self)
        }
    }

    @Published var currentRepeatMode: RepeatMode = .off {
        didSet {
            delegate?.musicPlayerManagerDidChangeRepeat(self)
        }
    }
    
    // MARK: - Audio Engine Properties
    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var secondaryPlayerNode: AVAudioPlayerNode!
    private var equalizer: AVAudioUnitEQ!
    private var audioFile: AVAudioFile?
    private var seekFrame: AVAudioFramePosition = 0
    private var playbackToken: UUID?
    private var timer: Timer?
    private var pendingAutomaticTransition: DispatchWorkItem?
    
    private var isEngineReady = false

    // Fade control
    private var fadeTimer: Timer?
    private var secondaryFadeTimer: Timer?
    private var isFading = false
    
    private var pendingPlaybackState: PlaybackState?
    private var hasRestoredFromPending = false
    
    // Settings
    private var settings = SettingsManager.shared
    private var settingsCancellables: Set<AnyCancellable> = []

    private func observePlaybackSettings() {
        Publishers.Merge(
            settings.$crossfadeDuration.map { _ in () },
            settings.$gaplessPlayback.map { _ in () }
        )
        .dropFirst(2)
        .receive(on: RunLoop.main)
        .sink { [weak self] in
            guard let self, self.isPlaying else { return }
            self.cancelPendingTransition()
            self.scheduleAutomaticTransition()
        }
        .store(in: &settingsCancellables)
    }
    
    private var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) else {
            return seekFrame
        }
        return seekFrame + playerTime.sampleTime
    }
    
    enum RepeatMode {
        case off, one, all
    }
    
    override init() {
        super.init()
        setupNotifications()
        setupWidgetCommandObserver()
        handleWidgetCommand()
        setupRemoteCommandCenter()
        observePlaybackSettings()
        
        pendingPlaybackState = PlaybackStateService.shared.loadPlaybackState()
        if pendingPlaybackState != nil {
            hasRestoredFromPending = false
        }
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        guard engine == nil else { return }
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        secondaryPlayerNode = AVAudioPlayerNode()
        equalizer = AVAudioUnitEQ(numberOfBands: 9)

        let frequencies: [Float] = [60, 150, 400, 1000, 2400, 15000, 20000]
        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = 100
        equalizer.bands[0].bypass = false

        for (index, freq) in frequencies.enumerated() {
            let bandIndex = index + 1
            equalizer.bands[bandIndex].filterType = .parametric
            equalizer.bands[bandIndex].frequency = freq
            equalizer.bands[bandIndex].bandwidth = 1
            equalizer.bands[bandIndex].bypass = false
        }

        equalizer.bands[8].filterType = .highShelf
        equalizer.bands[8].frequency = 10000
        equalizer.bands[8].bypass = false

        engine.attach(playerNode)
        engine.attach(secondaryPlayerNode)
        engine.attach(equalizer)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        engine.connect(secondaryPlayerNode, to: engine.mainMixerNode, format: nil)
        engine.connect(engine.mainMixerNode, to: equalizer, format: nil)
        engine.connect(equalizer, to: engine.outputNode, format: nil)
        setupAudioSession()
    }
    
    func ensureEngineReady() {
        guard !isEngineReady else { return }
        setupAudioEngine()
        isEngineReady = true
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
        if reason == .oldDeviceUnavailable {
            if isPlaying {
                playerNode.pause()
                isPlaying = false
                updateNowPlayingInfo()
            }
        }
    }
    
    // MARK: - EQ & Volume
    func updateEQ(settings: EqualizerSettings) {
        equalizer.bypass = !settings.isEnabled
        if !settings.isEnabled { return }
        if settings.isPreAmpEnabled {
            equalizer.globalGain = Float(settings.preAmpValue)
        } else {
            equalizer.globalGain = 0
        }
        if settings.isBassEnabled {
            equalizer.bands[0].gain = Float(settings.bassValue)
            equalizer.bands[0].bypass = false
        } else {
            equalizer.bands[0].gain = 0
            equalizer.bands[0].bypass = true
        }
        for (index, value) in settings.bands.enumerated() {
            let bandIndex = index + 1
            if bandIndex < equalizer.bands.count {
                equalizer.bands[bandIndex].gain = Float(value)
            }
        }
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
    
    // MARK: - Playback Control
    func playSong(_ song: Song) {
        playSongImmediately(song)
    }

    private func playSongImmediately(_ song: Song) {
        cancelPendingTransition()
        playerNode.volume = 1
        secondaryPlayerNode.volume = 0
        currentSong = song
        do {
            guard let fileURL = song.resolvedURL ?? song.url as URL? else {
                print("Error: Unable to resolve song URL")
                return
            }
            audioFile = try AVAudioFile(forReading: fileURL)
            guard let audioFile else { return }
            playerNode.stop()
            secondaryPlayerNode.stop()
            let token = UUID()
            playbackToken = token
            seekFrame = 0
            playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handlePlaybackFinished(token: token)
                }
            }
            if !engine.isRunning {
                try engine.start()
            }
            playerNode.play()
            isPlaying = true
            duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            artworkImage = song.artworkImage ?? getArtwork(for: song)
            currentTime = 0
            updateNowPlayingInfo()
            startTimer()
            scheduleAutomaticTransition()
            saveCurrentPlaybackState()
            updateWidgetData()
        } catch {
            print("Error playing song: \(error.localizedDescription)")
        }
    }

    private func handlePlaybackFinished(token: UUID) {
        guard token == playbackToken, isPlaying else { return }
        switch currentRepeatMode {
        case .off, .all:
            playNext(automatic: true)
        case .one:
            if let current = currentSong { playSongImmediately(current) }
        }
    }
    
    func playFromAllSongs(
        _ songs: [Song],
        startAt song: Song? = nil,
        fromPlaylist playlistName: String? = nil,
        shuffle: Bool = false,
        repeatMode: RepeatMode = .off
    ) {
        allSongs = songs
        originalPlaylist = songs
        shuffleIsActive = shuffle
        playQueue = []
        currentPlaylistName = playlistName
        isPlayingFromPlaylist = (playlistName != nil)
        currentRepeatMode = repeatMode
        
        if shuffleIsActive {
            shuffledPlaylist = allSongs.shuffled()
            currentIndex = 0
        } else {
            shuffledPlaylist = []
            currentIndex = 0
        }
        
        let playlistToUse = shuffleIsActive ? shuffledPlaylist : allSongs
        guard !playlistToUse.isEmpty else { return }
        
        if let startSong = song {
            if let index = playlistToUse.firstIndex(where: { $0.url == startSong.url }) {
                currentIndex = index
                currentSong = startSong
                playSong(startSong)
            } else {
                currentIndex = 0
                let firstSong = playlistToUse[0]
                currentSong = firstSong
                playSong(firstSong)
            }
        } else {
            let firstSong = playlistToUse[0]
            currentIndex = 0
            currentSong = firstSong
            playSong(firstSong)
        }
    }
    
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
        playNext(automatic: false)
    }

    private func playNext(automatic: Bool) {
        if ensurePlaybackStateAndCheckIfJustStarted() { return }
        guard let nextSong = advanceToNextSong() else {
            finishPlaylist()
            return
        }

        if automatic && settings.gaplessPlayback && settings.crossfadeDuration == 0 {
            playSongImmediately(nextSong)
        } else if settings.crossfadeDuration > 0 && isPlaying {
            crossfade(to: nextSong, duration: settings.crossfadeDuration)
        } else {
            playSongImmediately(nextSong)
        }
        saveCurrentPlaybackState()
    }

    private func advanceToNextSong() -> Song? {
        if !playQueue.isEmpty {
            let nextSong = playQueue.removeFirst()
            if let index = allSongs.firstIndex(where: { $0.url == nextSong.url }) {
                currentIndex = index
            }
            return nextSong
        }

        let playlist = activePlaylist
        guard !playlist.isEmpty else { return nil }
        switch currentRepeatMode {
        case .all:
            currentIndex = (currentIndex + 1) % playlist.count
            return playlist[currentIndex]
        case .one:
            return currentSong
        case .off:
            guard currentIndex < playlist.count - 1 else { return nil }
            currentIndex += 1
            return playlist[currentIndex]
        }
    }

    private func peekNextSong() -> Song? {
        if let queuedSong = playQueue.first { return queuedSong }
        let playlist = activePlaylist
        guard !playlist.isEmpty else { return nil }
        switch currentRepeatMode {
        case .all:
            return playlist[(currentIndex + 1) % playlist.count]
        case .one:
            return currentSong
        case .off:
            guard currentIndex < playlist.count - 1 else { return nil }
            return playlist[currentIndex + 1]
        }
    }

    private var activePlaylist: [Song] {
        shuffleIsActive ? (shuffledPlaylist.isEmpty ? allSongs : shuffledPlaylist) : allSongs
    }

    private func finishPlaylist() {
        cancelPendingTransition()
        playerNode.stop()
        secondaryPlayerNode.stop()
        isPlaying = false
        stopTimer()
        currentTime = duration
        updateNowPlayingInfo()
        saveCurrentPlaybackState()
        updateWidgetData()
    }

    func playPrevious() {
        if ensurePlaybackStateAndCheckIfJustStarted() { return }

        let playlist = activePlaylist
        guard !playlist.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        let previousSong: Song
        if currentRepeatMode == .one, let currentSong {
            previousSong = currentSong
        } else {
            currentIndex = (currentIndex - 1 + playlist.count) % playlist.count
            previousSong = playlist[currentIndex]
        }

        if settings.crossfadeDuration > 0 && isPlaying {
            crossfade(to: previousSong, duration: settings.crossfadeDuration)
        } else {
            playSongImmediately(previousSong)
        }
        saveCurrentPlaybackState()
    }
    
    func play() {
        if !isPlaying {
            togglePlayPause()
        }
    }
    
    func pause() {
        if isPlaying {
            togglePlayPause()
        }
    }
    
    // MARK: - Fade Helpers
    private func fade(
        node: AVAudioPlayerNode,
        from start: Float,
        to end: Float,
        duration: TimeInterval,
        timerKeyPath: ReferenceWritableKeyPath<MusicPlayerManager, Timer?>,
        completion: (() -> Void)? = nil
    ) {
        self[keyPath: timerKeyPath]?.invalidate()
        guard duration > 0 else {
            node.volume = end
            completion?()
            return
        }

        isFading = true
        let startTime = Date()
        let totalChange = end - start
        var timer: Timer?
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self, weak node] _ in
            guard let self, let node else { return }
            let progress = min(Date().timeIntervalSince(startTime) / duration, 1)
            node.volume = start + totalChange * Float(progress)

            if progress >= 1 {
                timer?.invalidate()
                self.isFading = false
                node.volume = end
                completion?()
            }
        }
        self[keyPath: timerKeyPath] = timer
    }

    private func fadeVolume(from start: Float, to end: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        fade(node: playerNode, from: start, to: end, duration: duration, timerKeyPath: \.fadeTimer, completion: completion)
    }

    private func crossfade(to song: Song, duration requestedDuration: TimeInterval) {
        pendingAutomaticTransition?.cancel()
        pendingAutomaticTransition = nil
        guard let fileURL = song.resolvedURL ?? song.url else {
            playSongImmediately(song)
            return
        }

        do {
            let nextFile = try AVAudioFile(forReading: fileURL)
            let outgoingNode = playerNode!
            let incomingNode = secondaryPlayerNode!
            incomingNode.stop()
            incomingNode.volume = 0
            if !engine.isRunning { try engine.start() }

            let token = UUID()
            playbackToken = token
            incomingNode.scheduleFile(nextFile, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handlePlaybackFinished(token: token)
                }
            }
            incomingNode.play()
            swap(&playerNode, &secondaryPlayerNode)

            audioFile = nextFile
            seekFrame = 0
            currentSong = song
            duration = Double(nextFile.length) / nextFile.processingFormat.sampleRate
            artworkImage = song.artworkImage ?? getArtwork(for: song)
            currentTime = 0
            isPlaying = true
            updateNowPlayingInfo()
            startTimer()
            scheduleAutomaticTransition()
            saveCurrentPlaybackState()
            updateWidgetData()

            let fadeDuration = min(requestedDuration, duration)
            fade(node: incomingNode, from: 0, to: 1, duration: fadeDuration, timerKeyPath: \.fadeTimer)
            fade(node: outgoingNode, from: 1, to: 0, duration: fadeDuration, timerKeyPath: \.secondaryFadeTimer) {
                outgoingNode.stop()
                outgoingNode.volume = 0
            }
        } catch {
            print("Error crossfading to song: \(error.localizedDescription)")
            playSongImmediately(song)
        }
    }

    private func cancelPendingTransition() {
        pendingAutomaticTransition?.cancel()
        pendingAutomaticTransition = nil
        fadeTimer?.invalidate()
        secondaryFadeTimer?.invalidate()
        secondaryFadeTimer = nil
        secondaryPlayerNode?.stop()
        secondaryPlayerNode?.volume = 0
    }
    
    // MARK: - Toggle Play/Pause with Fade
    func togglePlayPause() {
        guard let currentSong else {
            ensurePlaybackState()
            return
        }

        fadeTimer?.invalidate()
        secondaryFadeTimer?.invalidate()
        isFading = false

        if isPlaying {
            cancelPendingTransition()
            playerNode.pause()
            isPlaying = false
            updateNowPlayingInfo()
            saveCurrentPlaybackState()
            updateWidgetData()
        } else {
            if duration > 0 && currentTime >= duration {
                playSong(currentSong)
                return
            }

            if settings.fadeDuration > 0 {
                if !engine.isRunning { try? engine.start() }
                playerNode.volume = 0
                playerNode.play()
                isPlaying = true
                scheduleAutomaticTransition()
                let fadeSeconds = settings.fadeDuration / 1000
                fadeVolume(from: 0, to: 1, duration: fadeSeconds) { [weak self] in
                    self?.playerNode.volume = 1
                    self?.updateNowPlayingInfo()
                    self?.saveCurrentPlaybackState()
                    self?.updateWidgetData()
                }
            } else {
                if !engine.isRunning { try? engine.start() }
                playerNode.play()
                isPlaying = true
                scheduleAutomaticTransition()
                updateNowPlayingInfo()
                saveCurrentPlaybackState()
                updateWidgetData()
            }
        }
    }

    func stop() {
        cancelPendingTransition()
        playbackToken = nil
        playerNode.stop()
        secondaryPlayerNode.stop()
        isPlaying = false
        currentSong = nil
        artworkImage = nil
        stopTimer()
        PlaybackStateService.shared.clearPlaybackState()
        saveCurrentPlaybackState()
        updateWidgetData()
    }
    
    // MARK: - Shuffle & Repeat
    func toggleShuffle() {
        if shuffleIsActive {
            deactivateShuffle()
        } else {
            activateShuffle()
        }
        if shuffleIsActive && currentRepeatMode != .off {
            currentRepeatMode = .off
        }
    }
    
    private func activateShuffle() {
        guard !allSongs.isEmpty else { return }
        let currentSong = getCurrentSong()
        if let currentSong = currentSong {
            var songsToShuffle = allSongs.filter { $0.id != currentSong.id }
            songsToShuffle.shuffle()
            shuffledPlaylist = [currentSong] + songsToShuffle
            currentIndex = 0
        } else {
            shuffledPlaylist = allSongs.shuffled()
            currentIndex = 0
        }
        shuffleIsActive = true
    }
    
    private func deactivateShuffle() {
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
    
    func cycleRepeatMode() {
        if shuffleIsActive {
            deactivateShuffle()
        }
        switch currentRepeatMode {
        case .off: currentRepeatMode = .all
        case .all: currentRepeatMode = .one
        case .one: currentRepeatMode = .off
        }
    }
    
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
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self,
                  let nodeTime = self.playerNode.lastRenderTime,
                  let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime),
                  let file = self.audioFile else { return }
            let sampleRate = file.processingFormat.sampleRate
            let currentFrame = self.seekFrame + playerTime.sampleTime
            let time = min(Double(currentFrame) / sampleRate, self.duration)
            self.currentTime = time
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        }
    }

    private func scheduleAutomaticTransition() {
        pendingAutomaticTransition?.cancel()
        pendingAutomaticTransition = nil
        guard isPlaying, duration > currentTime else { return }
        guard peekNextSong() != nil else { return }

        if settings.crossfadeDuration > 0 {
            let fadeDuration = min(settings.crossfadeDuration, duration)
            let delay = max(duration - currentTime - fadeDuration, 0)
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, self.isPlaying else { return }
                guard let nextSong = self.advanceToNextSong() else {
                    self.finishPlaylist()
                    return
                }
                self.crossfade(to: nextSong, duration: fadeDuration)
            }
            pendingAutomaticTransition = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        } else if settings.gaplessPlayback {
            prepareGaplessTransition()
        }
    }

    private func prepareGaplessTransition() {
        guard let nextSong = peekNextSong(),
              let fileURL = nextSong.resolvedURL ?? nextSong.url,
              let nextFile = try? AVAudioFile(forReading: fileURL) else { return }

        let remaining = max(duration - currentTime, 0.05)
        let startHostTime = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: remaining)
        let startTime = AVAudioTime(hostTime: startHostTime)
        let token = UUID()

        secondaryPlayerNode.stop()
        secondaryPlayerNode.volume = 1
        playbackToken = token
        secondaryPlayerNode.scheduleFile(nextFile, at: startTime, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handlePlaybackFinished(token: token)
            }
        }
        secondaryPlayerNode.play(at: startTime)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isPlaying, self.playbackToken == token else { return }
            guard let committedSong = self.advanceToNextSong(), committedSong.id == nextSong.id else {
                self.cancelPendingTransition()
                return
            }

            swap(&self.playerNode, &self.secondaryPlayerNode)
            self.secondaryPlayerNode.stop()
            self.secondaryPlayerNode.volume = 0
            self.audioFile = nextFile
            self.seekFrame = 0
            self.currentSong = committedSong
            self.duration = Double(nextFile.length) / nextFile.processingFormat.sampleRate
            self.artworkImage = committedSong.artworkImage ?? self.getArtwork(for: committedSong)
            self.currentTime = 0
            self.updateNowPlayingInfo()
            self.startTimer()
            self.scheduleAutomaticTransition()
            self.saveCurrentPlaybackState()
            self.updateWidgetData()
        }
        pendingAutomaticTransition = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: workItem)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Playback State Persistence
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
        guard let state = PlaybackStateService.shared.loadPlaybackState() else { return }
        if allSongs.isEmpty {
            pendingPlaybackState = state
            hasRestoredFromPending = false
            return
        }
        
        applySavedState(state)
    }
    
    func restorePlaybackStateWithoutPlaying() {
        guard let state = PlaybackStateService.shared.loadPlaybackState() else { return }
        if allSongs.isEmpty {
            pendingPlaybackState = state
            hasRestoredFromPending = false
            return
        }
        applySavedState(state)
    }

    // MARK: - Playlist Setup (without playing)
    func setPlaylist(_ songs: [Song]) {
        allSongs = songs
        originalPlaylist = songs
        shuffledPlaylist = []
        shuffleIsActive = false
        currentIndex = 0

        if let state = pendingPlaybackState, !hasRestoredFromPending {
            applySavedState(state)
            hasRestoredFromPending = true
            pendingPlaybackState = nil
        }
    }
    
    private func applySavedState(_ state: PlaybackState) {
        guard let songURL = URL(string: state.songURL),
              FileManager.default.fileExists(atPath: songURL.path) else {
            PlaybackStateService.shared.clearPlaybackState()
            return
        }

        guard let index = allSongs.firstIndex(where: { $0.urlString == songURL.path }) else {
            PlaybackStateService.shared.clearPlaybackState()
            return
        }

        currentIndex = index
        let restoredSong = allSongs[index]

        // Perform file I/O on a background thread
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.loadSongWithoutPlaying(restoredSong, atPosition: state.playbackPosition)
        }
    }

    private func loadSongWithoutPlaying(_ song: Song, atPosition position: TimeInterval) async {
        guard let fileURL = song.resolvedURL ?? song.url else { return }
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            let sampleRate = audioFile.processingFormat.sampleRate
            let startFrame = AVAudioFramePosition(position * sampleRate)
            let remaining = AVAudioFrameCount(max(0, audioFile.length - startFrame))

            await MainActor.run {
                self.cancelPendingTransition()
                self.audioFile = audioFile
                self.duration = duration
                self.playerNode.stop()
                self.playerNode.volume = 1
                self.seekFrame = startFrame
                if remaining > 1000 {
                    let token = UUID()
                    self.playbackToken = token
                    self.playerNode.scheduleSegment(
                        audioFile,
                        startingFrame: startFrame,
                        frameCount: remaining,
                        at: nil,
                        completionCallbackType: .dataPlayedBack
                    ) { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.handlePlaybackFinished(token: token)
                        }
                    }
                }
                self.currentSong = song
                self.artworkImage = song.artworkImage ?? self.getArtwork(for: song)
                self.currentTime = position
                self.isPlaying = false
                self.updateNowPlayingInfo()
                self.startTimer()
            }
        } catch {
            print("Failed to load song without playing: \(error)")
        }
    }
    
    // MARK: - Artwork
    func getArtwork(for song: Song) -> UIImage {
        if let artwork = song.artworkImage { return artwork }
        guard let fileURL = song.resolvedURL ?? song.url as URL? else {
            return generateDefaultArtwork(size: CGSize(width: 600, height: 600))
        }
        let asset = AVAsset(url: fileURL)
        for meta in asset.commonMetadata {
            if meta.commonKey?.rawValue == "artwork",
               let data = meta.value as? Data,
               let image = UIImage(data: data) {
                return image
            }
        }
        return generateDefaultArtwork(size: CGSize(width: 600, height: 600))
    }
    
    func loadArtworkAsync(for song: Song) async -> UIImage {
        let key = NSString(string: song.urlString)
        if let cached = artworkCache.object(forKey: key) { return cached }
        if let artwork = song.artworkImage {
            artworkCache.setObject(artwork, forKey: key)
            return artwork
        }
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return self?.generateDefaultArtwork(size: CGSize(width: 600, height: 600)) ?? UIImage() }
            guard let fileURL = song.resolvedURL ?? song.url else {
                return self.generateDefaultArtwork(size: CGSize(width: 600, height: 600))
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
            let result = image ?? self.generateDefaultArtwork(size: CGSize(width: 600, height: 600))
            self.artworkCache.setObject(result, forKey: key)
            return result
        }.value
    }

    // MARK: - High‑quality default artwork generator (thread‑safe)
    private func generateDefaultArtwork(size: CGSize = CGSize(width: 600, height: 600)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width * 0.08).fill()
            let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.35, weight: .medium)
            // Use fixed purple color to avoid concurrency issues
            let purple = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
            if let note = UIImage(systemName: "music.note", withConfiguration: config)?
                .withTintColor(purple, renderingMode: .alwaysOriginal) {
                note.draw(at: CGPoint(
                    x: (size.width  - note.size.width)  / 2,
                    y: (size.height - note.size.height) / 2
                ))
            }
        }
    }
    
    func delete(song: Song) {
        let wasPlayingDeletedSong = currentSong == song && isPlaying

        if currentSong == song {
            stop()
            PlaybackStateService.shared.clearPlaybackState()
        }
        allSongs.removeAll { $0 == song }
        originalPlaylist.removeAll { $0 == song }
        shuffledPlaylist.removeAll { $0 == song }
        playQueue.removeAll { $0 == song }

        guard let fileURL = song.resolvedURL ?? song.url else {
            print("Failed to delete file: invalid song URL")
            return
        }
        
        // Perform file deletion on a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .songDeleted, object: nil, userInfo: ["song": song])
                    self.updateWidgetData()
                    if wasPlayingDeletedSong && !self.allSongs.isEmpty {
                        self.playNext()
                    }
                }
            } catch {
                print("Failed to delete file: \(error.localizedDescription)")
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        cancelPendingTransition()
        guard let audioFile else { return }
        let sampleRate = audioFile.processingFormat.sampleRate
        let clampedTime = min(max(time, 0), duration)
        let newFrame = AVAudioFramePosition(clampedTime * sampleRate)
        let frameCount = AVAudioFrameCount(max(0, audioFile.length - newFrame))
        playerNode.stop()
        let token = UUID()
        playbackToken = token
        if frameCount > 1000 {
            playerNode.scheduleSegment(
                audioFile,
                startingFrame: newFrame,
                frameCount: frameCount,
                at: nil,
                completionCallbackType: .dataPlayedBack
            ) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handlePlaybackFinished(token: token)
                }
            }
        }
        seekFrame = newFrame
        if isPlaying {
            playerNode.play()
            scheduleAutomaticTransition()
        }
        currentTime = clampedTime
        updateNowPlayingInfo()
    }
    
    // MARK: - Lock Screen & CarPlay Now Playing
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio Session Error: \(error.localizedDescription)") }
    }
    
    public func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String : Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        let artworkImage: UIImage
        if let img = song.artworkImage {
            artworkImage = img
        } else {
            artworkImage = generateDefaultArtwork(size: CGSize(width: 600, height: 600))
        }
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Remote Command Center
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        // Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        // Next Track
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        // Previous Track
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        // Seek
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
        
        // Enable commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
    
    // MARK: - Widget Data Update
    private func updateWidgetData() {
        let title = currentSong?.title
        let artist = currentSong?.artist
        let artworkData = currentSong?.artworkImage?.jpegData(compressionQuality: 0.8)
        SharedDataManager.shared.updateWidgetData(title: title, artist: artist, artworkData: artworkData, isPlaying: isPlaying)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        #endif
    }

    // MARK: - Ensure Playback State
    private func ensurePlaybackState() {
        if currentSong != nil && !allSongs.isEmpty {
            return
        }

        if allSongs.isEmpty, let container = modelContainer, Thread.isMainThread {
            let context = MainActor.assumeIsolated { container.mainContext }
            let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.title)])
            if let songs = try? context.fetch(descriptor), !songs.isEmpty {
                setPlaylist(songs)
            }
        }

        if allSongs.isEmpty {
            restoreLastPlaybackState()
        }

        // If we still have no current song after loading, we need to set one.
        // But note: applySavedState now loads asynchronously, so we might not have it yet.
        // However, we want to ensure UI is not blocked. We'll check again after a short delay if needed.
        if currentSong == nil && !allSongs.isEmpty {
            if currentIndex >= 0 && currentIndex < allSongs.count {
                let song = allSongs[currentIndex]
                // Load without playing asynchronously
                Task.detached(priority: .userInitiated) { [weak self] in
                    await self?.loadSongWithoutPlaying(song, atPosition: 0)
                }
            } else {
                // Fallback to first song – but also async
                let song = allSongs[0]
                Task.detached(priority: .userInitiated) { [weak self] in
                    await self?.loadSongWithoutPlaying(song, atPosition: 0)
                }
            }
        }

        if allSongs.isEmpty {
            print("⚠️ No songs available to play.")
        }
    }

    private func ensurePlaybackStateAndCheckIfJustStarted() -> Bool {
        let hadSongBefore = currentSong != nil
        ensurePlaybackState()
        return !hadSongBefore && currentSong != nil
    }

    private func setupWidgetCommandObserver() {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            notificationCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { (_, observer, name, _, _) in
                guard let observer = observer else { return }
                let manager = Unmanaged<MusicPlayerManager>.fromOpaque(observer).takeUnretainedValue()
                manager.handleWidgetCommand()
            },
            "com.NaaPaata.widgetCommand" as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func handleWidgetCommand() {
        guard let command = SharedDataManager.shared.readCommand() else { return }
        SharedDataManager.shared.clearCommand()
        
        DispatchQueue.main.async {
            self.ensurePlaybackState()
            switch command {
            case "playpause":
                self.togglePlayPause()
            case "next":
                self.playNext()
            case "previous":
                self.playPrevious()
            default:
                break
            }
        }
    }
}

extension Notification.Name {
    static let songDeleted = Notification.Name("songDeleted")
}
