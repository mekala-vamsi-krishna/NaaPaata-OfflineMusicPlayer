//
//  AudioPlayerService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation
import AVFoundation
import Combine

protocol AudioPlayerServiceProtocol: AnyObject {
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var elapsedPublisher: AnyPublisher<TimeInterval, Never> { get }
    var progressPublisher: AnyPublisher<Double, Never> { get }
    var trackDidFinishPublisher: AnyPublisher<Void, Never> { get }

    func load(url: URL) throws
    func play()
    func pause()
    func stop()
    func seek(toTime time: TimeInterval)
    func seek(toProgress progress: Double)
    func setVolume(_ volume: Float)
    func setLooping(_ looping: Bool)
    func applyEqualizer(_ settings: EqualizerSettings)
}

final class AudioPlayerService: AudioPlayerServiceProtocol {

    // MARK: - Engine

    private let engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 9)

    private var currentFile: AVAudioFile?
    private var seekFrame: AVAudioFramePosition = 0
    private var playbackToken: UUID?
    private var timer: Timer?
    private var duration: TimeInterval = 0
    private var isLooping = false
    private var isEngineReady = false

    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)
    private let elapsedSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    private let trackDidFinishSubject = PassthroughSubject<Void, Never>()

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        isPlayingSubject.eraseToAnyPublisher()
    }
    var elapsedPublisher: AnyPublisher<TimeInterval, Never> {
        elapsedSubject.eraseToAnyPublisher()
    }
    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }
    var trackDidFinishPublisher: AnyPublisher<Void, Never> {
        trackDidFinishSubject.eraseToAnyPublisher()
    }

    // MARK: - Init

    init() {
        configureEqualizer()
        activateAudioSession()
    }

    // MARK: - Engine setup

    private func prepareEngineIfNeeded() {
        guard !isEngineReady else { return }

        engine.attach(playerNode)
        engine.attach(equalizer)

        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        engine.connect(engine.mainMixerNode, to: equalizer, format: nil)
        engine.connect(equalizer, to: engine.outputNode, format: nil)

        isEngineReady = true
    }

    private func configureEqualizer() {
        let frequencies: [Float] = [60, 150, 400, 1000, 2400, 15000, 20000]

        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = 100
        equalizer.bands[0].bypass = false

        for (index, freq) in frequencies.enumerated() {
            let band = equalizer.bands[index + 1]
            band.filterType = .parametric
            band.frequency = freq
            band.bandwidth = 1
            band.bypass = false
        }

        equalizer.bands[8].filterType = .highShelf
        equalizer.bands[8].frequency = 10_000
        equalizer.bands[8].bypass = false
    }

    // MARK: - Load

    func load(url: URL) throws {
        prepareEngineIfNeeded()
        stopTimer()

        let file = try AVAudioFile(forReading: url)
        currentFile = file
        seekFrame = 0
        duration = Double(file.length) / file.processingFormat.sampleRate

        playerNode.stop()

        let token = UUID()
        playbackToken = token

        playerNode.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleFinished(token: token)
            }
        }

        elapsedSubject.send(0)
        progressSubject.send(0)
    }

    // MARK: - Transport

    func play() {
        prepareEngineIfNeeded()
        guard currentFile != nil else { return }

        if !engine.isRunning {
            try? engine.start()
        }
        playerNode.play()
        isPlayingSubject.send(true)
        startTimer()

        Task.detached(priority: .userInitiated) {
            try? AVAudioSession.sharedInstance().setActive(
                true,
                options: []
            )
        }
    }

    func pause() {
        playerNode.pause()
        isPlayingSubject.send(false)
        stopTimer()
    }

    func stop() {
        playerNode.stop()
        currentFile = nil
        playbackToken = nil
        seekFrame = 0
        isPlayingSubject.send(false)
        elapsedSubject.send(0)
        progressSubject.send(0)
        stopTimer()
    }

    // MARK: - Seek

    func seek(toTime time: TimeInterval) {
        guard let file = currentFile else { return }

        let sampleRate = file.processingFormat.sampleRate
        let clamped = min(max(time, 0), duration)
        let frame = AVAudioFramePosition(clamped * sampleRate)
        let remaining = AVAudioFrameCount(max(0, file.length - frame))

        playerNode.stop()

        let token = UUID()
        playbackToken = token

        if remaining > 1000 {
            playerNode.scheduleSegment(
                file,
                startingFrame: frame,
                frameCount: remaining,
                at: nil,
                completionCallbackType: .dataPlayedBack
            ) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleFinished(token: token)
                }
            }
        }

        seekFrame = frame
        if isPlayingSubject.value {
            playerNode.play()
        }

        elapsedSubject.send(clamped)
        progressSubject.send(duration > 0 ? clamped / duration : 0)
    }

    func seek(toProgress progress: Double) {
        guard duration > 0 else { return }
        seek(toTime: duration * min(max(progress, 0), 1))
    }

    // MARK: - Settings

    func setVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = min(max(volume, 0), 1)
    }

    func setLooping(_ looping: Bool) {
        isLooping = looping
    }

    // MARK: - Equalizer

    func applyEqualizer(_ settings: EqualizerSettings) {
        prepareEngineIfNeeded()

        equalizer.bypass = !settings.isEnabled
        guard settings.isEnabled else { return }

        equalizer.globalGain = settings.isPreAmpEnabled
            ? Float(settings.preAmpValue)
            : 0

        // Low shelf (bass)
        if settings.isBassEnabled {
            equalizer.bands[0].gain = Float(settings.bassValue)
            equalizer.bands[0].bypass = false
        } else {
            equalizer.bands[0].gain = 0
            equalizer.bands[0].bypass = true
        }

        // Parametric bands
        for (index, value) in settings.bands.enumerated() {
            let bandIndex = index + 1
            guard bandIndex < equalizer.bands.count else { continue }
            equalizer.bands[bandIndex].gain = Float(value)
        }

        // High shelf (treble)
        if settings.isTrebleEnabled {
            equalizer.bands[8].gain = Float(settings.trebleValue)
            equalizer.bands[8].bypass = false
        } else {
            equalizer.bands[8].gain = 0
            equalizer.bands[8].bypass = true
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let file = currentFile,
              let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return }

        let sampleRate = file.processingFormat.sampleRate
        let elapsed = Double(seekFrame + playerTime.sampleTime) / sampleRate
        let total = Double(file.length) / sampleRate
        let clamped = min(elapsed, total)

        elapsedSubject.send(clamped)
        progressSubject.send(total > 0 ? clamped / total : 0)
    }

    // MARK: - Finished

    private func handleFinished(token: UUID) {
        guard token == playbackToken else { return }

        if isLooping, let file = currentFile {
            seekFrame = 0
            playerNode.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleFinished(token: token)
                }
            }
            playerNode.play()
            return
        }

        isPlayingSubject.send(false)
        stopTimer()
        progressSubject.send(1)
        trackDidFinishSubject.send()
    }

    // MARK: - Session

    private func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default
        )

        Task.detached(priority: .userInitiated) {
            try? AVAudioSession.sharedInstance().setActive(
                true,
                options: []
            )
        }
    }
}
