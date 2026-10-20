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
    
    @State private var isCarPlayConnected = false
    
    private var barHeight: CGFloat {
        isDragging ? 10 : 6
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(isCarPlayConnected ? 0.1 : 0.25))
                        .frame(height: barHeight)
                    
                    // Filled track
                    Capsule()
                        .fill(Color.white.opacity(isCarPlayConnected ? 0.3 : 0.85))
                        .frame(width: max(0, geo.size.width * volume), height: barHeight)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Disable interaction if CarPlay is connected
                            guard !isCarPlayConnected else { return }
                            
                            isDragging = true
                            // Calculate new volume based on drag position
                            let percent = min(max(0, value.location.x / geo.size.width), 1)
                            volume = Double(percent)
                            SystemVolumeManager.shared.setVolume(Float(percent))
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .allowsHitTesting(!isCarPlayConnected)
            }
            .frame(height: 30)
            
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
            checkCarPlayConnection()
            
            Task.detached(priority: .userInitiated) {
                try? AVAudioSession.sharedInstance().setActive(true)
            }
            
            // Sync initial volume
            volume = Double(AVAudioSession.sharedInstance().outputVolume)
            
            observer = AVAudioSession.sharedInstance().observe(\.outputVolume) { session, _ in
                DispatchQueue.main.async {
                    if !isDragging {
                        volume = Double(session.outputVolume)
                    }
                }
            }
        }
        // Listen for audio route changes (plugging/unplugging CarPlay)
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { _ in
            checkCarPlayConnection()
        }
        .onDisappear {
            observer?.invalidate()
            observer = nil
        }
    }
    
    /// Checks if the current audio output is CarPlay.
    private func checkCarPlayConnection() {
        let session = AVAudioSession.sharedInstance()
        isCarPlayConnected = session.currentRoute.outputs.contains { $0.portType == .carAudio }
    }
}
