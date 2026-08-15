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
    private var equalizer: AVAudioUnitEQ!
    private var audioFile: AVAudioFile?
    private var seekFrame: AVAudioFramePosition = 0
    private var playbackToken: UUID?
    private var timer: Timer?
    
    // Fade control
    private var fadeTimer: Timer?
    private var isFading = false
    
    // Settings
    private var settings = SettingsManager.shared
    
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
        setupAudioEngine()
        setupNotifications()
        setupWidgetCommandObserver()
        handleWidgetCommand()
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        equalizer = AVAudioUnitEQ(numberOfBands: 9)
        
        let frequencies: [Float] = [60, 150, 400, 1000, 2400, 15000, 20000]
        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = 100
        equalizer.bands[0].bypass = false
        
        for (index, freq) in frequencies.enumerated() {
            let bandIndex = index + 1
            equalizer.bands[bandIndex].filterType = .parametric
            equalizer.bands[bandIndex].frequency = freq
            equalizer.bands[bandIndex].bandwidth = 1.0
            equalizer.bands[bandIndex].bypass = false
        }
        
        equalizer.bands[8].filterType = .highShelf
        equalizer.bands[8].frequency = 10000
        equalizer.bands[8].bypass = false
        
        engine.attach(playerNode)
        engine.attach(equalizer)
        engine.connect(playerNode, to: equalizer, format: nil)
        engine.connect(equalizer, to: engine.mainMixerNode, format: nil)
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
            artworkImage = song.artworkImage ?? getArtwork(for: song)
            updateNowPlayingInfo()
            startTimer()
            saveCurrentPlaybackState()
            updateWidgetData()
        } catch {
            print("Error playing song: \(error.localizedDescription)")
        }
    }
    
    private func handlePlaybackFinished(token: UUID) {
        guard token == playbackToken else { return }
        if isPlaying {
            switch currentRepeatMode {
            case .off: playNext()
            case .one: if let current = currentSong { playSong(current) }
            case .all: playNext()
            }
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
        if ensurePlaybackStateAndCheckIfJustStarted() { return }

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
                    playerNode.stop()
                    isPlaying = false
                    stopTimer()
                    currentTime = duration
                    updateNowPlayingInfo()
                    saveCurrentPlaybackState()
                    updateWidgetData()
                }
            }
            saveCurrentPlaybackState()
        }
    }
    
    func playPrevious() {
        if ensurePlaybackStateAndCheckIfJustStarted() { return }

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
            saveCurrentPlaybackState()
        }
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
    
    // MARK: - Fade Helper
    private func fadeVolume(from start: Float, to end: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard duration > 0 else {
            playerNode.volume = end
            completion?()
            return
        }

        isFading = true
        let startTime = Date()
        let totalChange = end - start
        var timer: Timer? = nil
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            let currentVolume = start + totalChange * Float(progress)
            self.playerNode.volume = currentVolume

            if progress >= 1.0 {
                timer?.invalidate()
                self.isFading = false
                self.playerNode.volume = end
                completion?()
            }
        }
        self.fadeTimer = timer
    }
    
    // MARK: - Toggle Play/Pause with Fade
    func togglePlayPause() {
        guard let currentSong = currentSong else {
            ensurePlaybackState()
            return
        }

        fadeTimer?.invalidate()
        isFading = false

        if isPlaying {
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
            
            if settings.fadeEnabled && settings.fadeDuration > 0 {
                if !engine.isRunning { try? engine.start() }
                playerNode.volume = 0.0
                playerNode.play()
                isPlaying = true
                let fadeSeconds = settings.fadeDuration / 1000.0
                fadeVolume(from: 0.0, to: 1.0, duration: fadeSeconds) { [weak self] in
                    self?.playerNode.volume = 1.0
                    self?.updateNowPlayingInfo()
                    self?.saveCurrentPlaybackState()
                    self?.updateWidgetData()
                }
            } else {
                if !engine.isRunning { try? engine.start() }
                playerNode.play()
                isPlaying = true
                updateNowPlayingInfo()
                saveCurrentPlaybackState()
                updateWidgetData()
            }
        }
    }
    
    func stop() {
        playbackToken = nil
        playerNode.stop()
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
        
        if !allSongs.isEmpty {
            if let index = allSongs.firstIndex(where: { $0.urlString == restoredSong.urlString }) {
                currentIndex = index
            } else {
                currentIndex = 0
            }
        }
        
        playSong(restoredSong)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if playbackState.playbackPosition > 0 {
                self.seek(to: playbackState.playbackPosition)
            }
        }
    }
    
    func restorePlaybackStateWithoutPlaying() {
        guard currentSong == nil else { return }
        guard let state = PlaybackStateService.shared.loadPlaybackState() else { return }
        loadPlaybackStateWithoutPlaying(state)
    }

    private func loadPlaybackStateWithoutPlaying(_ state: PlaybackState) {
        guard let songURL = URL(string: state.songURL),
              FileManager.default.fileExists(atPath: songURL.path) else {
            PlaybackStateService.shared.clearPlaybackState()
            return
        }

        let artwork = state.artworkData.flatMap { UIImage(data: $0) }
    
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path + "/"
        let relativePath = songURL.path.replacingOccurrences(of: docsPath, with: "")
        let song = Song(
            relativePath: relativePath,
            urlString: songURL.path,
            title: state.songTitle,
            artist: state.songArtist,
            duration: 0,
            artworkImage: artwork
        )

        currentSong = song
        artworkImage = artwork ?? generateDefaultArtwork(size: CGSize(width: 100, height: 100))
        currentTime  = state.playbackPosition
        isPlaying    = false

        if !allSongs.isEmpty,
           let index = allSongs.firstIndex(where: { $0.urlString == song.urlString }) {
            currentIndex = index
        }

        if !engine.isRunning {
            try? engine.start()
        }
        if let audioFile = try? AVAudioFile(forReading: songURL) {
            self.audioFile = audioFile
            duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            playerNode.stop()
            let sampleRate = audioFile.processingFormat.sampleRate
            let startFrame = AVAudioFramePosition(state.playbackPosition * sampleRate)
            let remaining  = AVAudioFrameCount(max(0, audioFile.length - startFrame))
            seekFrame = startFrame
            if remaining > 1000 {
                playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: remaining, at: nil) { [weak self] in
                    DispatchQueue.main.async { self?.handlePlaybackFinished(token: self?.playbackToken ?? UUID()) }
                }
            }
        }

        setupRemoteTransportControls()
        updateNowPlayingInfo()
    }

    // MARK: - Playlist Setup (without playing)
    func setPlaylist(_ songs: [Song]) {
        allSongs = songs
        originalPlaylist = songs
        shuffledPlaylist = []
        shuffleIsActive = false
        currentIndex = 0
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

    // MARK: - High‑quality default artwork generator
    private func generateDefaultArtwork(size: CGSize = CGSize(width: 600, height: 600)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width * 0.08).fill()
            let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.35, weight: .medium)
            if let note = UIImage(systemName: "music.note", withConfiguration: config)?
                .withTintColor(UIColor(AppColors.primary), renderingMode: .alwaysOriginal) {
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
        do {
            try FileManager.default.removeItem(at: fileURL)
            NotificationCenter.default.post(name: .songDeleted, object: nil, userInfo: ["song": song])
        } catch {
            print("Failed to delete file: \(error.localizedDescription)")
        }

        updateWidgetData()

        if wasPlayingDeletedSong && !allSongs.isEmpty {
            playNext()
        }
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
    
    private func setupRemoteTransportControls() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = true
        cc.pauseCommand.isEnabled = true
        cc.nextTrackCommand.isEnabled = true
        cc.previousTrackCommand.isEnabled = true
        cc.changePlaybackPositionCommand.isEnabled = true
        
        cc.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
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
    
    // MARK: - Ensure Playback State (for widget actions)
    private func ensurePlaybackState() {
        if currentSong == nil && allSongs.isEmpty {
            restoreLastPlaybackState()
        }

        if allSongs.isEmpty, let container = modelContainer, Thread.isMainThread {
            let context = MainActor.assumeIsolated { container.mainContext }
            let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.title)])
            if let songs = try? context.fetch(descriptor), !songs.isEmpty {
                setPlaylist(songs)
                if let current = currentSong,
                   let index = allSongs.firstIndex(where: { $0.relativePath == current.relativePath }) {
                    currentIndex = index
                }
            }
        }

        if currentSong == nil && !allSongs.isEmpty {
            playSong(allSongs[0])
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
