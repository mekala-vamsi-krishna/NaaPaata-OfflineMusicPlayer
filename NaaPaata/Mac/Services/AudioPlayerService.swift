//
//  AudioPlayerService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/15/26.
//

import AVFoundation
import Combine

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

final class AudioPlayerService: NSObject, AudioPlayerServiceProtocol {

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var duration: TimeInterval = 0
    private var isLooping = false

    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    private let elapsedSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let trackDidFinishSubject = PassthroughSubject<Void, Never>()

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        isPlayingSubject.eraseToAnyPublisher()
    }
    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }
    var elapsedPublisher: AnyPublisher<TimeInterval, Never> {
        elapsedSubject.eraseToAnyPublisher()
    }
    var trackDidFinishPublisher: AnyPublisher<Void, Never> {
        trackDidFinishSubject.eraseToAnyPublisher()
    }

    func load(url: URL) throws {
        stopTimer()
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.numberOfLoops = isLooping ? -1 : 0
        player.prepareToPlay()
        self.player = player
        self.duration = player.duration
        progressSubject.send(0)
        elapsedSubject.send(0)
    }

    func play() {
        guard let player else { return }
        player.play()
        isPlayingSubject.send(true)
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlayingSubject.send(false)
        stopTimer()
    }

    func seek(toProgress progress: Double) {
        guard let player, duration > 0 else { return }
        let clamped = min(max(progress, 0), 1)
        player.currentTime = duration * clamped
        progressSubject.send(clamped)
        elapsedSubject.send(player.currentTime)
    }
    
    func seek(toTime time: TimeInterval) {
        guard let player else { return }
        let clamped = min(max(time, 0), duration)
        player.currentTime = clamped
        elapsedSubject.send(clamped)
        progressSubject.send(duration > 0 ? clamped / duration : 0)
    }

    func setLooping(_ looping: Bool) {
        isLooping = looping
        player?.numberOfLoops = looping ? -1 : 0
    }

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
        guard let player, duration > 0 else { return }
        let elapsed = player.currentTime
        elapsedSubject.send(elapsed)
        progressSubject.send(elapsed / duration)
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlayingSubject.send(false)
        stopTimer()
        progressSubject.send(1)
        trackDidFinishSubject.send()
    }
}
