//
//  FFTProcessor.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/5/26.
//

import Foundation
import AVFAudio
import Accelerate

nonisolated final class FFTProcessor {

    let fftSize: Int
    let binCount: Int

    private let fftSetup: FFTSetup?
    private let window: [Float]
    private var smoothed: [Float]

    private var windowed: [Float]
    private var real: [Float]
    private var imag: [Float]
    private var magnitudes: [Float]
    private var decibels: [Float]

    init(fftSize: Int = 2048, binCount: Int = 64) {
        self.fftSize = fftSize
        self.binCount = binCount
        self.fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(fftSize))),
                                             FFTRadix(kFFTRadix2))
        self.windowed = [Float](repeating: 0, count: fftSize)
        self.real = [Float](repeating: 0, count: fftSize / 2)
        self.imag = [Float](repeating: 0, count: fftSize / 2)
        self.magnitudes = [Float](repeating: 0, count: fftSize / 2)
        self.decibels = [Float](repeating: 0, count: fftSize / 2)
        self.smoothed = [Float](repeating: 0, count: binCount)

        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        self.window = window
    }

    /// Accepts the read-only buffer delivered by `installAudioTap`.
    func process(buffer: AVReadOnlyAudioPCMBuffer) -> (spectrum: [Float], rms: Float) {
        guard let setup = fftSetup else { return (smoothed, 0) }
        let available = Int(buffer.frameLength)
        guard available >= fftSize else { return (smoothed, 0) }

        let channel = buffer.channelData(0)

        switch channel {

        case .float(let span):
            let stride = max(buffer.stride, 1)
            let sampleCount = span.count / stride
            let count = min(sampleCount, fftSize)

            for i in 0..<count {
                windowed[i] = span[i * stride]
            }
            // Zero-pad if the incoming buffer is shorter than fftSize.
            if count < fftSize {
                for i in count..<fftSize { windowed[i] = 0 }
            }

        default:
            // int16 / int32 — the mixer never produces these, but bail
            // gracefully if we ever get one.
            return (smoothed, 0)
        }

        // Apply the Hann window.
        vDSP_vmul(windowed, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        // RMS for the level meter.
        var rms: Float = 0
        vDSP_rmsqv(windowed, 1, &rms, vDSP_Length(fftSize))

        // Pack real signal into split-complex and run the FFT.
        windowed.withUnsafeBufferPointer { wPtr in
            real.withUnsafeMutableBufferPointer { rPtr in
                imag.withUnsafeMutableBufferPointer { iPtr in
                    var split = DSPSplitComplex(realp: rPtr.baseAddress!,
                                                imagp: iPtr.baseAddress!)
                    wPtr.baseAddress!.withMemoryRebound(
                        to: DSPComplex.self,
                        capacity: fftSize / 2
                    ) { cPtr in
                        vDSP_ctoz(cPtr, 2, &split, 1, vDSP_Length(fftSize / 2))
                    }
                    let log2n = vDSP_Length(log2(Float(fftSize)))
                    vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                    vDSP_zvabs(&split, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
                }
            }
        }

        // Linear → dB.
        var one: Float = 1
        vDSP_vdbcon(magnitudes, 1, &one, &decibels, 1,
                    vDSP_Length(fftSize / 2), 1)

        // Downsample to binCount log-spaced buckets, normalized to 0…1.
        let halfN = fftSize / 2
        let minBin = 2
        let maxBin = halfN - 2
        let logMin = logf(Float(minBin))
        let logMax = logf(Float(maxBin))
        let logRange = logMax - logMin

        for i in 0..<binCount {
            let t0 = Float(i) / Float(binCount)
            let t1 = Float(i + 1) / Float(binCount)
            let start = Int(expf(logMin + t0 * logRange))
            let end   = min(Int(expf(logMin + t1 * logRange)), halfN)
            var sum: Float = 0
            var count = 0
            for j in max(start, minBin)..<max(end, minBin + 1) {
                sum += decibels[j]
                count += 1
            }
            let avg = count > 0 ? sum / Float(count) : -100
            let normalized = max(0, min(1, (avg + 80) / 80))
            smoothed[i] = smoothed[i] * 0.72 + normalized * 0.28
        }

        return (smoothed, min(rms * 4, 1))
    }
}
