//
//  VolumeSliderView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/14/26.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct VolumeSliderView: View {
    @State private var volume: Double = Double(AVAudioSession.sharedInstance().outputVolume)
    @State private var observer: NSKeyValueObservation?
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
            
            Slider(value: $volume, in: 0...1, onEditingChanged: { editing in
                isDragging = editing
            })
            .tint(.white.opacity(0.85))
            .onChange(of: volume) { oldValue, newValue in
                if isDragging {
                    SystemVolumeManager.shared.setVolume(Float(newValue))
                }
            }
            
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
        }
        .foregroundStyle(.white.opacity(0.6))
        .background(
            HiddenVolumeView()
                .frame(width: 1, height: 1)
                .opacity(0.001)
                .allowsHitTesting(false)
        )
        .onAppear {
            Task.detached(priority: .userInitiated) {
                try? AVAudioSession.sharedInstance().setActive(true)
            }
            
            // Sync initial state
            volume = Double(AVAudioSession.sharedInstance().outputVolume)
            
            observer = AVAudioSession.sharedInstance().observe(\.outputVolume) { session, _ in
                DispatchQueue.main.async {
                    if !isDragging {
                        volume = Double(session.outputVolume)
                    }
                }
            }
        }
        .onDisappear {
            observer?.invalidate()
            observer = nil
        }
    }
}
