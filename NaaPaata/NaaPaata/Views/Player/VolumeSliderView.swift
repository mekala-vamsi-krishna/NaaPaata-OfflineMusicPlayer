//
//  VolumeSliderView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/14/26.
//

import SwiftUI
import AVFoundation

struct VolumeSliderView: View {
    @State private var volume: Double = Double(AVAudioSession.sharedInstance().outputVolume)
    @State private var observer: NSKeyValueObservation?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
            
            Slider(value: $volume, in: 0...1)
                .tint(.white.opacity(0.85))
                .onChange(of: volume) { oldValue, newValue in
                    SystemVolumeManager.shared.setVolume(Float(newValue))
                }
            
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
        }
        .foregroundStyle(.white.opacity(0.6))
        .onAppear {
            // Sync slider with hardware buttons
            observer = AVAudioSession.sharedInstance().observe(\.outputVolume) { session, _ in
                DispatchQueue.main.async {
                    volume = Double(session.outputVolume)
                }
            }
        }
        .onDisappear {
            observer?.invalidate()
            observer = nil
        }
    }
}
