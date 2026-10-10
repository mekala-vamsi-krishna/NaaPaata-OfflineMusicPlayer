//
//  EqualizerEngine.swift
//  NaaPaataForMac
//

import Foundation
import AVFAudio
import Accelerate
import Combine


// MARK: - Sendable tap state

private nonisolated final class TapState: @unchecked Sendable {

    let fft: FFTProcessor

    /// The audio thread reads this on every tap callback.
    /// The main actor writes it when the equalizer window opens or closes.
    let visible = OSAllocatedUnfairLock(initialState: false)

    /// Publishes FFT results back to the main actor.
    let updates = PassthroughSubject<Update, Never>()

    struct Update {
        let spectrum: [Float]
        let level: Double
        let clipping: Bool
    }

    init(fft: FFTProcessor) {
        self.fft = fft
    }
}

// MARK: - Equalizer Engine

@MainActor
final class EqualizerEngine: ObservableObject {

    @Published private(set) var spectrum: [Float] = Array(repeating: 0, count: 64)
    @Published private(set) var inputLevel: Double = 0
    @Published private(set) var isClipping: Bool = false

    var isVisible: Bool {
        get { tapState.visible.withLock { $0 } }
        set { tapState.visible.withLock { $0 = newValue } }
    }

    private weak var engine: AVAudioEngine?
    private weak var sourceNode: AVAudioNode?
    private weak var destinationNode: AVAudioNode?
    private var eqNode: AVAudioUnitEQ?

    var isAttached: Bool { eqNode != nil }

    private let tapState: TapState
    private var clipResetTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let fft = FFTProcessor(fftSize: 2048, binCount: 64)
        self.tapState = TapState(fft: fft)

        // Route tap updates back onto the main actor.
        tapState.updates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self else { return }
                self.spectrum = update.spectrum
                self.inputLevel = update.level
                if update.clipping {
                    self.isClipping = true
                    self.scheduleClipReset()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Attach / Detach

    func attach(
        to engine: AVAudioEngine,
        source: AVAudioNode,
        destination: AVAudioNode
    ) throws {
        guard !isAttached else { return }
        detach()

        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }

        self.engine = engine
        self.sourceNode = source
        self.destinationNode = destination

        let eq = AVAudioUnitEQ(numberOfBands: 10)
        eq.globalGain = 0
        eq.bypass = true

        for band in eq.bands {
            band.filterType = .parametric
            band.frequency = 1_000
            band.bandwidth = 1.0
            band.gain = 0
            band.bypass = false
        }

        self.eqNode = eq

        engine.attach(eq)
        engine.disconnectNodeOutput(source)

        engine.connect(source, to: eq, format: nil)
        engine.connect(eq, to: destination, format: nil)

        installSpectrumTap(on: eq)

        if wasRunning {
            engine.prepare()
            try engine.start()
        }
    }

    func detach() {
        clipResetTask?.cancel()
        clipResetTask = nil

        guard let eq = eqNode,
              let engine,
              let source = sourceNode,
              let dest = destinationNode
        else {
            eqNode = nil
            return
        }

        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }

        eq.removeTap(onBus: 0)
        engine.disconnectNodeOutput(eq)

        try? engine.connect(
            source,
            to: dest,
            fromBus: 0,
            toBus: 0,
            format: nil
        )

        engine.detach(eq)

        if wasRunning {
            engine.prepare()
            try? engine.start()
        }

        eqNode = nil
        self.engine = nil
        self.sourceNode = nil
        self.destinationNode = nil
    }

    // MARK: - Apply Settings (unchanged)

    func apply(bands: [EQBand], preamp: Double, enabled: Bool) {
        guard let eq = eqNode else { return }

        if enabled {
            eq.bypass = false
            eq.globalGain = Float(preamp)

            for (i, band) in bands.enumerated() where i < eq.bands.count {
                let eqBand = eq.bands[i]
                eqBand.filterType = mapFilterType(band.filterType)
                eqBand.frequency = Float(band.frequency)
                eqBand.bandwidth = Float(min(max(band.q, 0.05), 5.0))
                eqBand.gain = band.isEnabled ? Float(band.gain) : 0
            }
        } else {
            eq.globalGain = 0
            for eqBand in eq.bands { eqBand.gain = 0 }
            eq.bypass = true
        }
    }

    private func mapFilterType(_ type: EQBand.FilterType) -> AVAudioUnitEQFilterType {
        switch type {
        case .peaking:   return .parametric
        case .lowShelf:  return .lowShelf
        case .highShelf: return .highShelf
        case .lowPass:   return .lowPass
        case .highPass:  return .highPass
        case .notch:     return .bandStop
        }
    }

    // MARK: - Spectrum Tap

    private func installSpectrumTap(on node: AVAudioNode) {
        let format = node.outputFormat(forBus: 0)

        // Capture the Sendable state object, never `self`.
        let state = tapState

        node.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(tapState.fft.fftSize),
            format: format
        ) { buffer, _ in
            // Skip everything if the EQ window isn't visible.
            guard state.visible.withLock({ $0 }) else { return }

            let result = state.fft.process(buffer: buffer)

            state.updates.send(
                TapState.Update(
                    spectrum: result.spectrum,
                    level: Double(result.rms),
                    clipping: result.rms > 0.95
                )
            )
        }
    }

    private func scheduleClipReset() {
        clipResetTask?.cancel()
        clipResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.isClipping = false
        }
    }
}
