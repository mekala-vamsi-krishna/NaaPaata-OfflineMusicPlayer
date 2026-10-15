//
//  SystemVolumeManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/14/26.
//

import SwiftUI
import MediaPlayer
import AVFoundation

final class SystemVolumeManager {
    static let shared = SystemVolumeManager()
    
    // Weak reference to the MPVolumeView that lives in the SwiftUI hierarchy
    weak var volumeView: MPVolumeView?
    
    private init() {}
    
    func setVolume(_ value: Float) {
        guard let slider = findSlider(in: volumeView) else { return }
        DispatchQueue.main.async {
            slider.value = value
        }
    }
    
    private func findSlider(in view: UIView?) -> UISlider? {
        guard let view = view else { return nil }
        if let slider = view as? UISlider { return slider }
        for sub in view.subviews {
            if let found = findSlider(in: sub) { return found }
        }
        return nil
    }
}

// MARK: - Hidden Volume View
struct HiddenVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsVolumeSlider = true
        view.alpha = 0.0001
        SystemVolumeManager.shared.volumeView = view
        return view
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        SystemVolumeManager.shared.volumeView = uiView
    }
}
