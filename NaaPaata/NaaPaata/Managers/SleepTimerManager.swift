//
//  SleepTimerManager.swift
//  NaaPaata
//
//  Created by Antigravity on 2/16/26.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class SleepTimerManager: ObservableObject {

    @Published var timeRemaining: TimeInterval = 0
    @Published var isTimerActive: Bool = false

    private var timer: AnyCancellable?
    private var modelContext: ModelContext?
    private var timerModel: SleepTimerModel?

    var libraryViewModel: MusicLibraryViewModel?

    static let shared = SleepTimerManager()

    private init() {}

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchOrCreateTimerModel()
    }

    private func fetchOrCreateTimerModel() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<SleepTimerModel>()
        if let models = try? modelContext.fetch(descriptor), let model = models.first {
            self.timerModel = model
            checkExistingTimer()
        } else {
            let newModel = SleepTimerModel()
            modelContext.insert(newModel)
            self.timerModel = newModel
        }
    }

    private func checkExistingTimer() {
        guard let model = timerModel,
              model.isEnabled,
              let targetDate = model.targetDate
        else { return }

        if targetDate > Date() {
            startCountdown(targetDate: targetDate)
        } else {
            stopTimer()
        }
    }

    // MARK: - Public API

    func setTimer(hours: Int, minutes: Int) {
        guard let model = timerModel else {
            assertionFailure("SleepTimerManager.setTimer called before setup(modelContext:). Call SleepTimerManager.shared.setup(...) at app launch.")
            return
        }

        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        guard totalSeconds > 0 else {
            stopTimer()
            return
        }

        let targetDate = Date().addingTimeInterval(totalSeconds)
        model.hours = hours
        model.minutes = minutes
        model.isEnabled = true
        model.targetDate = targetDate

        try? modelContext?.save()
        startCountdown(targetDate: targetDate)
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
        isTimerActive = false
        timeRemaining = 0

        if let model = timerModel {
            model.isEnabled = false
            model.targetDate = nil
            try? modelContext?.save()
        }
    }

    // MARK: - Countdown

    private func startCountdown(targetDate: Date) {
        isTimerActive = true
        updateTimeRemaining(targetDate: targetDate)

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining(targetDate: targetDate)
            }
    }

    private func updateTimeRemaining(targetDate: Date) {
        let now = Date()
        if targetDate <= now {
            triggerSleep()
        } else {
            timeRemaining = targetDate.timeIntervalSince(now)
        }
    }

    private func triggerSleep() {
        stopTimer()
        libraryViewModel?.pausePlayback()
    }

    // MARK: - Formatting

    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
