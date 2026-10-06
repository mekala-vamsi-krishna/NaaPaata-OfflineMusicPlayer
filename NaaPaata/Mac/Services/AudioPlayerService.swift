//
//  AudioPlayerService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/15/26.
//

import AVFoundation
import Combine

// MARK: - Sendable weak reference box
//
// Wraps a weak reference so it can be safely captured in @Sendable
// closures. The `@unchecked Sendable` is justified because the only
// access to `value` happens on the main actor (inside `Task { @MainActor }`).
private final class WeakBox<T: AnyObject>: @unchecked Sendable {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

protocol AudioPlayerServiceProtocol: AnyObject {
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var progressPublisher: AnyPublisher<Double, Never> { get }
    var elapsedPublisher: AnyPublisher<TimeInterval, Never> { get }
    var trackDidFinishPublisher: AnyPublisher<Void, Never> { get }

    func load(url: URL) throws
    func play()
    func pause()
    func seek(toProgress progress: Double)
    func seek(toTime time: TimeInterval)
    func setLooping(_ looping: Bool)
}

final class AudioPlayerService: AudioPlayerServiceProtocol, ObservableObject {

    // MARK: - Public graph (the equalizer attaches to these)

    let audioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()

    // MARK: - Private state

    private var audioFile: AVAudioFile?
    private var duration: TimeInterval = 0
    private var isLooping = false

    private var segmentStartFrame: AVAudioFramePosition = 0
    private var playGeneration: UInt64 = 0

    private var timer: Timer?

    // MARK: - Publishers

    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    private let elapsedSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let trackDidFinishSubject = PassthroughSubject<Void, Never>()

    var isPlayingPublisher: AnyPublisher<Bool, Never> { isPlayingSubject.eraseToAnyPublisher() }
    var progressPublisher: AnyPublisher<Double, Never> { progressSubject.eraseToAnyPublisher() }
    var elapsedPublisher: AnyPublisher<TimeInterval, Never> { elapsedSubject.eraseToAnyPublisher() }
    var trackDidFinishPublisher: AnyPublisher<Void, Never> { trackDidFinishSubject.eraseToAnyPublisher() }
    
    var currentPosition: TimeInterval { currentSeconds() }
    var isPlaying: Bool { playerNode.isPlaying }

    // MARK: - Init

    init() {
        audioEngine.attach(playerNode)

        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)

        do {
            try audioEngine.connectNode(
                playerNode,
                to: audioEngine.mainMixerNode,
                format: format
            )
        } catch {
            print("AudioPlayerService: connectNode failed: \(error)")
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("AudioPlayerService: engine start failed: \(error)")
        }
    }

    // MARK: - Load

    func load(url: URL) throws {
        playerNode.stop()
        playGeneration &+= 1
        stopTimer()

        let file = try AVAudioFile(forReading: url)
        audioFile = file
        duration = Double(file.length) / file.processingFormat.sampleRate
        segmentStartFrame = 0

        progressSubject.send(0)
        elapsedSubject.send(0)

        scheduleCurrentSegment()
    }

    // MARK: - Transport

    func play() {
        guard audioFile != nil else { return }
        if !audioEngine.isRunning { try? audioEngine.start() }

        do {
            try playerNode.playAudio()
            isPlayingSubject.send(true)
            startTimer()
        } catch {
            print("AudioPlayerService: playAudio failed: \(error)")
        }
    }

    func pause() {
        playerNode.pause()
        isPlayingSubject.send(false)
        stopTimer()
    }

    func seek(toProgress progress: Double) {
        guard duration > 0 else { return }
        let clamped = min(max(progress, 0), 1)
        seek(toSeconds: duration * clamped)
    }

    func seek(toTime time: TimeInterval) {
        let clamped = min(max(time, 0), duration)
        seek(toSeconds: clamped)
    }

    private func seek(toSeconds seconds: TimeInterval) {
        guard let file = audioFile else { return }

        let wasPlaying = playerNode.isPlaying
        playerNode.stop()
        playGeneration &+= 1
        stopTimer()

        let sampleRate = file.processingFormat.sampleRate
        let targetFrame = AVAudioFramePosition(seconds * sampleRate)
        let remaining = AVAudioFrameCount(max(0, file.length - targetFrame))

        segmentStartFrame = targetFrame

        if remaining > 0 {
            let generation = playGeneration
            let weakSelf = WeakBox(self)

            playerNode.scheduleSegment(
                file,
                startingFrame: targetFrame,
                frameCount: remaining,
                at: nil
            ) {
                Task { @MainActor in
                    guard let self = weakSelf.value,
                          self.playGeneration == generation
                    else { return }
                    self.handleFileFinished()
                }
            }
        }

        elapsedSubject.send(seconds)
        progressSubject.send(duration > 0 ? seconds / duration : 0)

        if wasPlaying {
            do { try playerNode.playAudio() } catch { /* ignored */ }
            startTimer()
        }
    }

    func setLooping(_ looping: Bool) {
        isLooping = looping
    }

    // MARK: - Scheduling

    private func scheduleCurrentSegment() {
        guard let file = audioFile else { return }

        playGeneration &+= 1
        let generation = playGeneration

        let weakSelf = WeakBox(self)

        playerNode.scheduleFile(file, at: nil) {
            Task { @MainActor in
                guard let self = weakSelf.value,
                      self.playGeneration == generation
                else { return }
                self.handleFileFinished()
            }
        }
        segmentStartFrame = 0
    }
    
    func invalidateScheduledCompletion() {
        playGeneration &+= 1
    }

    private func handleFileFinished() {
        if isLooping {
            scheduleCurrentSegment()
            do { try playerNode.playAudio() } catch { /* ignored */ }
        } else {
            isPlayingSubject.send(false)
            stopTimer()
            progressSubject.send(1)
            trackDidFinishSubject.send()
        }
    }

    // MARK: - Progress timer

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
        guard duration > 0 else { return }
        let seconds = currentSeconds()
        let clamped = min(max(seconds, 0), duration)
        elapsedSubject.send(clamped)
        progressSubject.send(clamped / duration)
    }

    private func currentSeconds() -> TimeInterval {
        guard let file = audioFile,
              let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else {
            let sampleRate = audioFile?.processingFormat.sampleRate ?? 44_100
            return Double(segmentStartFrame) / sampleRate
        }
        let fileFrame = segmentStartFrame + playerTime.sampleTime
        return Double(fileFrame) / file.processingFormat.sampleRate
    }
}
