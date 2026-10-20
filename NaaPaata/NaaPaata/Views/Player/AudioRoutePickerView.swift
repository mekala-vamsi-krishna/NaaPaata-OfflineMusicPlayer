//
//  AudioRoutePickerView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/20/26.
//

import SwiftUI
import AVFAudio
import AVKit

struct AudioRoutePickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .white
        picker.activeTintColor = .systemPink
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
