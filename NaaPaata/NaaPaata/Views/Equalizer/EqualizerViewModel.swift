//
//  EqualizerViewModel.swift
//  NaaPaata
//

import Foundation
import Combine

@MainActor
final class EqualizerViewModel: ObservableObject {

    // MARK: - Published
    @Published var isEnabled: Bool = true {
        didSet { updateEQ() }
    }

    @Published var selectedPreset: String = "Custom" {
        didSet {
            if selectedPreset != "Custom" {
                applyPreset(selectedPreset)
            }
            saveSettings()
        }
    }

    @Published var preAmpValue: Double = 0.0 {
        didSet {
            if !isApplyingPreset && selectedPreset != "Custom" { selectedPreset = "Custom" }
            updateEQ()
        }
    }
    @Published var bassValue: Double = 0.0 {
        didSet {
            if !isApplyingPreset && selectedPreset != "Custom" { selectedPreset = "Custom" }
            updateEQ()
        }
    }
    @Published var trebleValue: Double = 0.0 {
        didSet {
            if !isApplyingPreset && selectedPreset != "Custom" { selectedPreset = "Custom" }
            updateEQ()
        }
    }

    @Published var isPreAmpEnabled: Bool = true { didSet { updateEQ() } }
    @Published var isBassEnabled: Bool = true { didSet { updateEQ() } }
    @Published var isTrebleEnabled: Bool = true { didSet { updateEQ() } }

    @Published var volume: Double = 0.75 { didSet { updateVolume() } }

    @Published var bands: [Double] = [0, 0, 0, 0, 0, 0, 0] {
        didSet {
            if !isApplyingPreset && selectedPreset != "Custom" {
                selectedPreset = "Custom"
            }
            updateEQ()
        }
    }

    let frequencies = ["60Hz", "150Hz", "400Hz", "1kHz", "2.4kHz", "15kHz", "20kHz"]
    let presets = [
        "Custom", "Flat", "Bass Boost", "Bass Reducer",
        "Treble Boost", "Treble Reducer", "Vocal Booster",
        "Electronic", "Hip-Hop", "Jazz", "Pop", "Rock"
    ]

    private var isApplyingPreset = false

    private let playerService: AudioPlayerServiceProtocol

    init(playerService: AudioPlayerServiceProtocol) {
        self.playerService = playerService
        loadSettings()
    }

    // MARK: - Preset selection

    func selectPreset(_ preset: String) {
        selectedPreset = preset
    }

    private func applyPreset(_ name: String) {
        isApplyingPreset = true
        defer { isApplyingPreset = false }

        preAmpValue = 0
        bassValue = 0
        trebleValue = 0

        switch name {
        case "Flat":
            setBands([0, 0, 0, 0, 0, 0, 0])
        case "Bass Boost":
            setBands([5, 4, 2, 0, 0, 0, 0])
            bassValue = 4
        case "Bass Reducer":
            setBands([-5, -4, -2, 0, 0, 0, 0])
            bassValue = -4
        case "Treble Boost":
            setBands([0, 0, 0, 0, 2, 4, 5])
            trebleValue = 4
        case "Treble Reducer":
            setBands([0, 0, 0, 0, -2, -4, -5])
            trebleValue = -4
        case "Vocal Booster":
            setBands([-2, -2, 2, 4, 2, -1, -2])
        case "Electronic":
            setBands([4, 3, 0, -2, 2, 3, 4])
            bassValue = 2
            trebleValue = 2
        case "Hip-Hop":
            setBands([5, 4, 1, -1, 1, 3, 4])
            bassValue = 5
        case "Jazz":
            setBands([3, 2, -1, 2, -1, 2, 3])
        case "Pop":
            setBands([-1, 1, 3, 4, 2, -1, -2])
        case "Rock":
            setBands([4, 3, -1, -2, 1, 3, 4])
        default:
            break
        }

        updateEQ()
    }

    private func setBands(_ values: [Double]) {
        bands = values
        updateEQ()
    }

    // MARK: - Engine integration

    private func updateEQ() {
        let settings = currentSettings
        playerService.applyEqualizer(settings)
        saveSettings()
    }

    private func updateVolume() {
        playerService.setVolume(Float(volume))
    }

    // MARK: - Persistence

    private var currentSettings: EqualizerSettings {
        EqualizerSettings(
            isEnabled: isEnabled,
            preAmpValue: preAmpValue,
            bassValue: bassValue,
            trebleValue: trebleValue,
            bands: bands,
            selectedPreset: selectedPreset,
            isPreAmpEnabled: isPreAmpEnabled,
            isBassEnabled: isBassEnabled,
            isTrebleEnabled: isTrebleEnabled
        )
    }

    private func saveSettings() {
        guard let encoded = try? JSONEncoder().encode(currentSettings) else { return }
        UserDefaults.standard.set(encoded, forKey: "EqualizerSettings")
    }

    private func loadSettings() {
        guard
            let data = UserDefaults.standard.data(forKey: "EqualizerSettings"),
            let settings = try? JSONDecoder().decode(EqualizerSettings.self, from: data)
        else { return }

        isApplyingPreset = true

        isEnabled = settings.isEnabled
        preAmpValue = settings.preAmpValue
        bassValue = settings.bassValue
        trebleValue = settings.trebleValue
        bands = settings.bands
        selectedPreset = settings.selectedPreset
        isPreAmpEnabled = settings.isPreAmpEnabled
        isBassEnabled = settings.isBassEnabled
        isTrebleEnabled = settings.isTrebleEnabled

        isApplyingPreset = false

        playerService.applyEqualizer(settings)
    }

    // MARK: - Manual band change

    func bandChanged(index: Int, value: Double) {
        bands[index] = value
        if selectedPreset != "Custom" {
            selectedPreset = "Custom"
        }
        updateEQ()
    }
}
