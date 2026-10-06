//
//  EqualizerViewModel.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import Foundation
import Combine

@MainActor
final class EqualizerViewModel: ObservableObject {

    // MARK: - State

    @Published var isEnabled: Bool = false
    @Published var bands: [EQBand]
    @Published var preamp: Double = 0          // dB
    @Published var selectedPresetID: UUID?
    @Published var presets: [EqualizerPreset]
    @Published var searchQuery: String = ""
    @Published var parametricMode: Bool = false

    /// A/B comparison — `curveB` holds a stashed state, toggled by the
    /// header "A/B" button. If `showingB` is true, the sliders display B.
    @Published var showingB: Bool = false
    private(set) var curveA: [Double] = []
    private(set) var curveB: [Double] = []

    /// Live input level (0…1) and clip indicator, updated by the engine.
    @Published var inputLevel: Double = 0
    @Published var isClipping: Bool = false

    /// The spectrum bands the analyzer view renders. 64 buckets by default.
    @Published var spectrum: [Float] = Array(repeating: 0, count: 64)

    /// Set when a persistence operation fails — the sidebar can show this.
    @Published var persistenceError: String?

    let frequencies = EqualizerPreset.frequencies

    weak var engine: EqualizerEngine?

    // MARK: - Storage

    private let presetStore: PresetStore

    // MARK: - Init

    init(presetStore: PresetStore = FilePresetStore()) {
        self.presetStore = presetStore
        self.bands = EqualizerPreset.frequencies.map { EQBand(frequency: $0) }
        self.presets = Self.builtInPresets()

        loadCustomPresets()
        bindPublishers()
    }

    private var cancellables = Set<AnyCancellable>()

    private func bindPublishers() {
        $bands
            .dropFirst()
            .sink { [weak self] _ in self?.notifyEngine() }
            .store(in: &cancellables)

        $preamp
            .dropFirst()
            .sink { [weak self] _ in self?.notifyEngine() }
            .store(in: &cancellables)

        $isEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.notifyEngine() }
            .store(in: &cancellables)
    }

    // MARK: - Persistence

    private func loadCustomPresets() {
        do {
            let custom = try presetStore.loadCustomPresets()
            presets.append(contentsOf: custom)
        } catch {
            persistenceError = "Could not load custom presets: \(error.localizedDescription)"
        }
    }

    private func persistCustomPresets() {
        let custom = presets.filter { !$0.isBuiltIn }
        do {
            try presetStore.saveCustomPresets(custom)
            persistenceError = nil
        } catch {
            persistenceError = "Could not save presets: \(error.localizedDescription)"
        }
    }

    // MARK: - Engine bridge

    private func notifyEngine() {
        engine?.apply(bands: bands, preamp: preamp, enabled: isEnabled)
    }

    func syncEngine() {
        notifyEngine()
    }

    // MARK: - Band editing

    func setGain(_ value: Double, at index: Int) {
        guard bands.indices.contains(index) else { return }
        bands[index].gain = clamp(value)
    }

    func setQ(_ value: Double, at index: Int) {
        guard bands.indices.contains(index) else { return }
        bands[index].q = min(max(value, 0.1), 10)
    }

    func resetBand(at index: Int) {
        guard bands.indices.contains(index) else { return }
        bands[index].gain = 0
    }

    func toggleBand(at index: Int) {
        guard bands.indices.contains(index) else { return }
        bands[index].isEnabled.toggle()
    }

    func resetAll() {
        bands = frequencies.map { EQBand(frequency: $0) }
        preamp = 0
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, -12), 12)
    }

    // MARK: - Presets

    func apply(_ preset: EqualizerPreset) {
        selectedPresetID = preset.id
        preamp = preset.preamp

        for (i, gain) in preset.bands.enumerated() where bands.indices.contains(i) {
            bands[i].gain = gain
        }
        // Applying a preset is NOT a mutation of the preset list.
        // No persistence call here.
    }

    func saveCurrentAsPreset(name: String, category: EqualizerPreset.Category = .custom) {
        let preset = EqualizerPreset(
            id: UUID(),
            name: name,
            category: category,
            bands: bands.map(\.gain),
            preamp: preamp,
            isBuiltIn: false,
            dateCreated: Date()
        )
        presets.append(preset)
        selectedPresetID = preset.id
        persistCustomPresets()
    }

    func deletePreset(_ preset: EqualizerPreset) {
        guard !preset.isBuiltIn else { return }
        presets.removeAll { $0.id == preset.id }
        if selectedPresetID == preset.id { selectedPresetID = nil }
        persistCustomPresets()
    }

    func renamePreset(_ preset: EqualizerPreset, to newName: String) {
        guard !preset.isBuiltIn else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[idx].name = trimmed
        persistCustomPresets()
    }

    var filteredPresets: [EqualizerPreset] {
        guard !searchQuery.isEmpty else { return presets }
        return presets.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var groupedPresets: [(EqualizerPreset.Category, [EqualizerPreset])] {
        let order: [EqualizerPreset.Category] = [.custom, .genre, .reference, .builtIn]
        let grouped = Dictionary(grouping: filteredPresets, by: \.category)
        return order.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (cat, items.sorted { $0.name < $1.name })
        }
    }

    // MARK: - A/B

    func stashToA() {
        curveA = bands.map(\.gain)
    }

    func stashToB() {
        curveB = bands.map(\.gain)
    }

    func recallA() {
        guard !curveA.isEmpty else { return }
        for (i, g) in curveA.enumerated() where bands.indices.contains(i) {
            bands[i].gain = g
        }
        showingB = false
    }

    func recallB() {
        guard !curveB.isEmpty else { return }
        for (i, g) in curveB.enumerated() where bands.indices.contains(i) {
            bands[i].gain = g
        }
        showingB = true
    }

    // MARK: - Built-in presets

    private static func builtInPresets() -> [EqualizerPreset] {
        func make(_ name: String, _ cat: EqualizerPreset.Category, _ gains: [Double], preamp: Double = 0) -> EqualizerPreset {
            EqualizerPreset(
                id: UUID(),
                name: name,
                category: cat,
                bands: gains,
                preamp: preamp,
                isBuiltIn: true,
                dateCreated: .distantPast
            )
        }
        return [
            make("Flat",             .builtIn, [0,0,0,0,0,0,0,0,0,0]),
            make("Loudness",         .builtIn, [6,4,0,-1,-2,0,2,4,5,6]),
            make("Rock",             .genre,   [5,4,2,0,-1,-1,1,3,4,5]),
            make("Pop",              .genre,   [-1,0,2,4,4,2,1,0,-1,-2]),
            make("Hip-Hop",          .genre,   [6,5,3,1,0,-1,0,1,2,3]),
            make("Jazz",             .genre,   [3,2,1,2,-1,-1,0,1,2,3]),
            make("Classical",        .genre,   [3,2,1,0,-1,-1,0,2,3,4]),
            make("Electronic",       .genre,   [5,4,2,0,-1,0,2,4,5,6]),
            make("Acoustic",         .genre,   [3,2,1,1,0,0,1,2,3,3]),
            make("Vocal Boost",      .genre,   [-3,-2,-1,1,3,4,4,3,1,-1]),
            make("Bass Boost",       .genre,   [7,6,5,3,1,0,0,0,0,0], preamp: -3),
            make("Treble Boost",     .genre,   [0,0,0,0,0,0,2,4,5,6]),
            make("Reference Flat",   .reference, [0,0,0,0,0,0,0,0,0,0]),
            make("Broadcast",        .reference, [-4,-2,0,2,3,3,2,0,-1,-2], preamp: -2),
            make("Night Mode",       .reference, [-2,0,3,4,3,2,1,0,-1,-2], preamp: -3),
        ]
    }
}
